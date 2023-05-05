FROM ubuntu:jammy
ENV TRAC_ADMIN_NAME trac_admin
ENV TRAC_ADMIN_PASSWD passw0rd
ENV TRAC_PROJECT_NAME trac_project
ENV TRAC_DIR /var/local/trac
ENV TRAC_INI $TRAC_DIR/conf/trac.ini
ENV DB_LINK sqlite:db/trac.db
EXPOSE 8123

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apache2-utils apache2 trac git libapache2-mod-wsgi-py3 python3-pip && apt-get -y clean && rm -rf /var/lib/apt
RUN pip install --upgrade Babel Trac
RUN pip install 'Jinja2<3'
RUN mkdir -p $TRAC_DIR && mkdir -p /repos && mkdir -p staging
RUN trac-admin $TRAC_DIR initenv $TRAC_PROJECT_NAME $DB_LINK
RUN trac-admin $TRAC_DIR deploy /tmp/deploy
RUN mv /tmp/deploy/* $TRAC_DIR && cp $TRAC_DIR/db/trac.db /staging && cp $TRAC_DIR/conf/trac.ini /staging
RUN trac-admin $TRAC_DIR permission add $TRAC_ADMIN_NAME TRAC_ADMIN
RUN chown -R www-data: $TRAC_DIR && chmod -R 775 $TRAC_DIR
RUN echo "Listen 8123" >> /etc/apache2/ports.conf
ADD trac.conf /etc/apache2/sites-available/trac.conf
RUN sed -i 's|$AUTH_NAME|'"$TRAC_PROJECT_NAME"'|g' /etc/apache2/sites-available/trac.conf
RUN sed -i 's|$TRAC_DIR|'"$TRAC_DIR"'|g' /etc/apache2/sites-available/trac.conf
RUN a2dissite 000-default && a2ensite trac.conf
CMD service apache2 stop && apache2ctl -D FOREGROUND
