FROM choros

MAINTAINER Georg Grab

ARG SERV_BRANCH=master
ARG SITE_BRANCH=master


RUN git clone -b $SERV_BRANCH https://github.com/Chorknaben/chr-serv /ChorServ
RUN git clone -b $SITE_BRANCH https://github.com/Chorknaben/chr-site /ChorServ/static
RUN rm -f /ChorServ/static/data && ln -s /data /ChorServ/static/data
RUN rm -f /ChorServ/data && ln -s /data /ChorServ/data

WORKDIR "/ChorServ"
ENTRYPOINT ["./ChorServ"]
EXPOSE 8000
