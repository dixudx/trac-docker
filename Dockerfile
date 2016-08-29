FROM ubuntu:xenial
MAINTAINER = Di Xu <stephenhsu90@gmail.com>
ENV TRAC_ADMIN_NAME trac_admin
ENV TRAC_ADMIN_PASSWD passw0rd
ENV TRAC_PROJECT_NAME trac_project
ENV TRAC_DIR /var/local/trac
ENV DB_LINK sqlite:db/trac.db
EXPOSE 8123
RUN apt-get update && apt-get install -y trac python-babel libapache2-mod-python
RUN mkdir -p $TRAC_DIR
RUN trac-admin $TRAC_DIR initenv $TRAC_PROJECT_NAME $DB_LINK
RUN htpasswd -b -c $TRAC_DIR/.htpasswd $TRAC_ADMIN_NAME $TRAC_ADMIN_PASSWD
RUN trac-admin $TRAC_DIR permission add $TRAC_ADMIN_NAME TRAC_ADMIN
RUN chown -R www-data: $TRAC_DIR
RUN chmod -R 775 $TRAC_DIR
ADD trac.conf /etc/apache2/sites-available/trac.conf
RUN sed -i 's|$AUTH_NAME|'"$TRAC_PROJECT_NAME"'|g' /etc/apache2/sites-available/trac.conf
RUN sed -i 's|$TRAC_DIR|'"$TRAC_DIR"'|g' /etc/apache2/sites-available/trac.conf
RUN a2enmod python
RUN a2ensite trac.conf
CMD service apache2 restart
