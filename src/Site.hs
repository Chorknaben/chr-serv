{-# LANGUAGE OverloadedStrings, DoAndIfThenElse #-}

------------------------------------------------------------------------------
-- | This module is where all the routes and handlers are defined for your
-- site. The 'app' function is the initializer that combines everything
-- together and is exported by this module.
module Site
  ( app
  ) where

------------------------------------------------------------------------------
import           Control.Applicative
import           Data.ByteString (ByteString)
import           Data.ByteString.Lazy (toStrict)
import qualified Data.Text as T
import           Snap.Core
import           Snap.Snaplet
import           Snap.Snaplet.Auth
import           Snap.Snaplet.Auth.Backends.JsonFile
import           Snap.Snaplet.Heist
import           Snap.Snaplet.Session.Backends.CookieSession
import           Snap.Util.FileServe
import           Snap.Util.GZip
import           Data.Time.Clock.POSIX
import           Heist
import           Foreign.C.Types
import qualified Heist.Interpreted as I
import qualified Data.Set as S
import qualified Data.Map as M
import           System.Process

import           Graphics.GD
import           Text.Printf
import           Control.Monad.IO.Class
import           Control.Monad
import qualified Data.ByteString.Char8 as BS
import           Data.Maybe
import           System.Posix.Files 
import           System.Directory
import           System.IO

import           IMGScale
import           Data.Aeson
------------------------------------------------------------------------------
import           Application


-- Own Code

-- | Hard Coded image path will do for now.
imgroot :: FilePath
imgroot = "data"

-- | getBG serves the background image of the index page to the client.
--   as for the other functions related to serving images to the client,
--   it serves the image closest to the clients screen resolution.
getBG :: Handler App App ()
getBG = do
    width  <- decodeInt "width"
    height <- decodeInt "height"
    let bgPath x y = printf "%s/%d-%d-chorhintergrund.png" imgroot x y
    exists <- liftIO (fileExist $ bgPath width height)
    if exists then
        -- serve background image
        serveFile $ bgPath width height
    else 
        let (closeX, closeY) = getCloseMatch (width, height) in
        serveFile $ bgPath closeX closeY

getBGBlur :: Handler App App ()
getBGBlur = do
    width  <- decodeInt "width"
    height <- decodeInt "height"
    let bgPath x y = printf "%s/blur/%d-%d-chorhintergrund.png" imgroot x y
    exists <- liftIO (fileExist $ bgPath width height)
    if exists then
        -- serve background image
        serveFile $ bgPath width height
    else 
        let (closeX, closeY) = getCloseMatch (width, height) in
        serveFile $ bgPath closeX closeY

-- | Converts a String to an Int.
--   Note that the exception read may produce is delegated
--   into Snap Exception Handler and will thus not result
--   in a crash of the application.
asInt :: String -> Int
asInt a = (read a) :: Int

-- | getTile returns a tile close to the actual screen dimensions of the client
--   tileID identifies which tile is being requested:
--                 -----------------------------
--   (navigation)  | 8 | | 9 | | 10| | 11| | 12|
--   (tile-col 1)  | 1 | | 2 | | 3 | |    7    |
--   (tile-col 2)  | 4 | | 5 | | 6 | |         |
--                 -----------------------------
getTile :: Handler App App ()
getTile = do
    width  <- decodeInt "width"
    height <- decodeInt "height"
    tileID <- decodeInt "tileID"
    exists <- liftIO (fileExist (printf "%s/%d-%d-chorhintergrund.-%d.png" imgroot width height tileID))
    if exists then do
        -- serve background tiles
        serveFile $ printf "%s/%d-%d-chorhintergrund-%d.png" imgroot width height tileID
    else do
        let (closeX, closeY) = getCloseMatch (width, height)
        serveFile $ printf "%s/%d-%d-chorhintergrund-%d.png" imgroot closeX closeY tileID

-- | getImageThumbs serves image thumbnails located in the corresponding file system location.
--   the thumbnails filenames in the thumbnail directory match the thumbID sent by the client.
--   ex. thumbID=5 serves "image/thumbs/5"
--   Note that decodeInt prevents a possible code injection vulnerability.
getImageThumbs :: Handler App App ()
getImageThumbs = do
    thumbID <- decodeInt "id"
    exists  <- liftIO (fileExist (printf "%s/image/thumbs/%d" imgroot thumbID))
    if exists then serveFileAs "image/jpeg" (printf "%s/image/thumbs/%d" imgroot thumbID)
    else writeBS "{\"err\":\"ENODEAL\"}"

getImageReal :: Handler App App ()
getImageReal = do
    thumbID <- decodeInt "id"
    exists  <- liftIO (fileExist (printf "%s/image/real/%d" imgroot thumbID))
    if exists then serveFileAs "image/jpeg" (printf "%s/image/real/%d" imgroot thumbID)
    else writeBS "{\"err\":\"ENODEAL\"}"

-- | unsafeDecode is a small wrapper for getParam, converting its return value from
--   m (Maybe ByteString) to m [Char] in order to be easier to work with.
--   Note that unsafe doesn't stand for the fact that this function might throw an exception
--   due to the usage of fromJust - this function is unsafe because no input validation is done
--   whatsoever. 
--   The "unsafe" is a reminder to sanitize input in case of working with f.e SQL Databases in order
--   to prevent SQL-Injection.
unsafeDecode :: MonadSnap m => ByteString -> m [Char]
unsafeDecode a = getParam a >>= return . BS.unpack . fromJust

-- | decodeInt gets an Integer from getParam.
--   Throws an exception if argument is not an Integer.
decodeInt :: MonadSnap m => ByteString -> m Int
decodeInt bs = return . read =<< unsafeDecode bs

--handleBackend :: Handler App App ()
--handleBackend = do
--todo create backend
    
data HandlerResponse = HandlerResponse
    { numtiles :: Int
    }

instance ToJSON HandlerResponse where
    toJSON (HandlerResponse numtiles) = object ["numtiles" .= numtiles]
    
-- | handleNumRequest returns the number of image tiles the client should generate.
--   this also includes image categories (not yet implemented)
handleNumRequest :: Handler App App ()
handleNumRequest = do
    numImages <- liftIO $ liftM length $ getDirectoryContents (printf "%s/image/thumbs" imgroot)
    writeBS $ toStrict $ encode (HandlerResponse {numtiles = numImages - 2})

handleGoogleBot :: BS.ByteString -> Handler App App ()
handleGoogleBot match = do
    content <- liftIO (readFile "mirror.lookup")
    let line = lines content
    maybeMatch <- liftIO (getMaybeMatch line match)
    case maybeMatch of
      Nothing -> writeBS "404"
      Just a -> do
        content <- liftIO (readFile (printf "mirror/doms/%s.html" (BS.unpack a)))
        modifyResponse (setContentType "text/html;charset=utf-8")
        writeBS $ BS.pack content
  where
    getMaybeMatch :: [String] -> BS.ByteString -> IO (Maybe ByteString)
    getMaybeMatch [] _ = return $ Nothing
    getMaybeMatch (x:xs) match = do
      m <- doesMatch match x    
      case m of
        Nothing -> getMaybeMatch xs match
        (Just a) -> return $ Just a

    doesMatch :: BS.ByteString -> String -> IO (Maybe ByteString)
    doesMatch match h = let splitted = BS.split ' ' (BS.pack h) in
      if head splitted == match then
        return $ Just $ last splitted
      else return Nothing

defaultRoute :: Handler App App ()
defaultRoute = do
    a <- getParam "_escaped_fragment"
    case a of
      Nothing -> do
        b <- getParam "_escaped_fragment_"
        case b of
          Nothing -> serveDirectory "static"
          Just match -> handleGoogleBot match
      Just match -> handleGoogleBot match

handleGetFeedback :: Handler App App ()
handleGetFeedback = do
    req  <- getRequest
    let params = rqParams req
    let paramCheck = [M.findWithDefault ["invalid"] "email" params,
             M.findWithDefault ["invalid"] "name"  params,
             M.findWithDefault ["invalid"] "feedbacktype" params,
             M.findWithDefault ["invalid"] "text" params]

    if ["invalid"] `elem` paramCheck then
      -- Only called if client-side checks are oversprungen
      writeBS "Incorrect Data supplied"
    else
      if 2 /= (length $ BS.split '@' (head paramCheck !! 0)) then
        -- Very rudimentary check
        writeBS "Invalid E-Mail supplied"
      else do
        liftIO (BS.writeFile "/tmp/chorserv-feedback-email" (head $ head paramCheck))
        liftIO (BS.writeFile "/tmp/chorserv-feedback-name" (head $ paramCheck !! 1))
        liftIO (BS.writeFile "/tmp/chorserv-feedback-feedbacktype" (head $ paramCheck !! 2))
        liftIO (BS.writeFile "/tmp/chorserv-feedback-text" ( head $ paramCheck !! 3))
        liftIO (readProcess "./handle-get-feedback.sh" [] [])
        writeBS "OK"





------------------------------------------------------------------------------
-- | The application's routes.
routes :: [(ByteString, Handler App App ())]
routes = [ ("/images/thumbs/:id",      cStatic getImageThumbs)
         , ("/images/real/:id",        cStatic getImageReal)
         , ("/images/num",             cStatic handleNumRequest)
         , ("/feedback",               method POST handleGetFeedback)
         , ("/:width/:height/bg",      cStatic getBG)
         , ("/:width/:height/bg/blurred", cStatic getBGBlur)
         , ("/:width/:height/:tileID/tile", cStatic getTile)
         , ("/langheader"              , getLangHeader)
         , ("",                        cShort defaultRoute)
         ]

getLangHeader :: Handler App App ()
getLangHeader = do
  req <- getRequest
  case getHeader "Accept-language" req of
    Just a -> writeBS a
    Nothing -> writeBS "noheadersent"

epochTime :: IO CTime
epochTime = do
    t <- getPOSIXTime
    return $ fromInteger $ truncate    t

cStatic :: MonadSnap m => m a -> m ()
cStatic = setCache 604800 

cShort :: MonadSnap m => m a -> m ()
cShort = setCache 86400

setCache :: (MonadSnap m) => CTime -> m a -> m ()
setCache num action = do
    pinfo <- liftM rqPathInfo getRequest
    action
    expTime <- liftM (+num) $ liftIO epochTime
    s       <- liftIO $ formatHttpTime expTime
    modifyResponse $
        setHeader "Cache-Control" "public, max-age=604800" .
        setHeader "Expires" s

------------------------------------------------------------------------------
-- | The application initializer.
app :: SnapletInit App App
app = makeSnaplet "app" "An snaplet example application." Nothing $ do
    h <- nestSnaplet "" heist $ heistInit "templates"
    s <- nestSnaplet "sess" sess $
           initCookieSessionManager "site_key.txt" "sess" (Just 3600)

    -- NOTE: We're using initJsonFileAuthManager here because it's easy and
    -- doesn't require any kind of database server to run.  In practice,
    -- you'll probably want to change this to a more robust auth backend.
    a <- nestSnaplet "auth" auth $
           initJsonFileAuthManager defAuthSettings sess "users.json"
    wrapSite (\h -> withCompression' compressibleMimeTypes h)
    addRoutes routes
    addAuthSplices h auth
    return $ App h s a

compressibleMimeTypes :: S.Set ByteString
compressibleMimeTypes = S.fromList [ "application/x-font-truetype"
                                     , "application/x-javascript"
                                     , "text/css"
                                     , "text/html"
                                     , "text/javascript"
                                     , "text/plain"
                                     , "image/svg+xml"
                                     , "text/xml" ]