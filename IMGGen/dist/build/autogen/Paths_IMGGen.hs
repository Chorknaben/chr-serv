module Paths_IMGGen (
    version,
    getBinDir, getLibDir, getDataDir, getLibexecDir,
    getDataFileName, getSysconfDir
  ) where

import qualified Control.Exception as Exception
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude

catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
catchIO = Exception.catch


version :: Version
version = Version {versionBranch = [0,1,0,0], versionTags = []}
bindir, libdir, datadir, libexecdir, sysconfdir :: FilePath

bindir     = "/home/svt/.cabal/bin"
libdir     = "/home/svt/.cabal/lib/x86_64-linux-ghc-7.8.4/IMGGen-0.1.0.0"
datadir    = "/home/svt/.cabal/share/x86_64-linux-ghc-7.8.4/IMGGen-0.1.0.0"
libexecdir = "/home/svt/.cabal/libexec"
sysconfdir = "/home/svt/.cabal/etc"

getBinDir, getLibDir, getDataDir, getLibexecDir, getSysconfDir :: IO FilePath
getBinDir = catchIO (getEnv "IMGGen_bindir") (\_ -> return bindir)
getLibDir = catchIO (getEnv "IMGGen_libdir") (\_ -> return libdir)
getDataDir = catchIO (getEnv "IMGGen_datadir") (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "IMGGen_libexecdir") (\_ -> return libexecdir)
getSysconfDir = catchIO (getEnv "IMGGen_sysconfdir") (\_ -> return sysconfdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
