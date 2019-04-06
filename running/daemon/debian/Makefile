XIADA_INSTALL_DIR=/usr/local/xiada
XIADA_USER=xiada
XIADA_GROUP=staff

install: create_directories copy permissions daemon_install
uninstall: remove_directories daemon_uninstall

create_directories:
	mkdir -p $(XIADA_INSTALL_DIR)
	mkdir -p $(XIADA_INSTALL_DIR)/running
	mkdir -p $(XIADA_INSTALL_DIR)/training/databases
	mkdir -p $(XIADA_INSTALL_DIR)/lib
	sudo chown 755 $(XIADA_INSTALL_DIR)

remove_directories:
	rm -rf $(XIADA_INSTALL_DIR)

copy:
	cp -r ../../* $(XIADA_INSTALL_DIR)/running/
	cp ../../../lib/* $(XIADA_INSTALL_DIR)/lib
	cp -r ../../../training/databases/* $(XIADA_INSTALL_DIR)/training/databases

daemon_install:

	/bin/cp xiada.service /etc/systemd/system/
	/bin/cp xiada /etc/init.d

daemon_uninstall:
	service xiada stop
	rm -f /etc/init.d/xiada
	rm -f /etc/systemd/system/xiada.service

permissions:
	sudo chown -R $(XIADA_USER):$(XIADA_GROUP) $(XIADA_INSTALL_DIR)

clean_local:
	find .. -name "*~" | xargs rm

# Install in debian before systemd

presystemd_daemon_install:

	/bin/cp xiada /etc/init.d
	/bin/rm -rf /var/run/xiada
	/bin/mkdir /var/run/xiada
	/bin/chown xiada /var/run/xiada
	/bin/chgrp xiada /var/run/xiada
	/bin/touch /var/log/xiada.log
	/bin/chown xiada /var/log/xiada.log
	/bin/chgrp xiada /var/log/xiada.log
	/sbin/insserv xiada

presystemd_daemon_uninstall:

	/etc/init.d/xiada stop
	/sbin/insserv -r xiada
	rm -f /etc/init.d/xiada