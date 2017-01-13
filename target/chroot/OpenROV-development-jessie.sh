#!/bin/sh -e
#
# Copyright (c) 2014 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
set -x
set -e

export LC_ALL=C

u_boot_release="v2016.11-rc3"
u_boot_release_x15="ti-2016.05"
#bone101_git_sha="50e01966e438ddc43b9177ad4e119e5274a0130d"

#contains: rfs_username, release_date
if [ -f /etc/rcn-ee.conf ] ; then
	. /etc/rcn-ee.conf
fi

if [ -f /etc/oib.project ] ; then
	. /etc/oib.project
fi

export HOME=/home/${rfs_username}
export USER=${rfs_username}
export USERNAME=${rfs_username}

echo "env: [`env`]"

is_this_qemu () {
	unset warn_qemu_will_fail
	if [ -f /usr/bin/qemu-arm-static ] ; then
		warn_qemu_will_fail=1
	fi
}

qemu_warning () {
	if [ "${warn_qemu_will_fail}" ] ; then
		echo "Log: (chroot) Warning, qemu can fail here... (run on real armv7l hardware for production images)"
		echo "Log: (chroot): [${qemu_command}]"
	fi
}

git_clone () {
	mkdir -p ${git_target_dir} || true
	qemu_command="git clone ${git_repo} ${git_target_dir} --depth 1 || true"
	qemu_warning
	git clone ${git_repo} ${git_target_dir} --depth 1 || true
	sync
	echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
}

git_clone_branch () {
	mkdir -p ${git_target_dir} || true
	qemu_command="git clone -b ${git_branch} ${git_repo} ${git_target_dir} --depth 1 || true"
	qemu_warning
	git clone -b ${git_branch} ${git_repo} ${git_target_dir} --depth 1 || true
	sync
	echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
}

git_clone_full () {
	mkdir -p ${git_target_dir} || true
	qemu_command="git clone ${git_repo} ${git_target_dir} || true"
	qemu_warning
	git clone ${git_repo} ${git_target_dir} || true
	sync
	echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
}

install_dep_from_url () {
	wget ${deb_url}/${deb_package}
	dpkg -i ${deb_package}
	rm ${deb_package}
}

cleanup_npm_cache () {
	if [ -d /root/tmp/ ] ; then
		rm -rf /root/tmp/ || true
	fi

	if [ -d /root/.npm ] ; then
		rm -rf /root/.npm || true
	fi


	 if [ -f /home/${rfs_username}/.npmrc ] ; then
	 	rm -f /home/${rfs_username}/.npmrc || true
	 fi
}

#TODO: These packages need to be deployed to the deb repo for production image
install_custom_pkgs () {

	# Nginx-common
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/nginx/nginx-common_1.9.10-1~bpo8%202_all.deb
	dpkg -i nginx-common_1.9.10-1~bpo8\ 2_all.deb
	rm nginx-common_1.9.10-1~bpo8\ 2_all.deb

	# Nginx-light
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/nginx/nginx-light_1.9.10-1~bpo8%202_armhf.deb
	dpkg -i nginx-light_1.9.10-1~bpo8\ 2_armhf.deb
	rm nginx-light_1.9.10-1~bpo8\ 2_armhf.deb

	# ZeroMQ
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/gitlab/armhf/libzmq/libzmq_4.1.6_armhf.deb
	dpkg -i libzmq_4.1.6_armhf.deb
	rm libzmq_4.1.6_armhf.deb

	# GC6500 Apps
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/geocamera-libs/openrov-geocamera-utils_1.0.0-1~35.16a26aa_armhf.deb
	dpkg -i openrov-geocamera-utils_1.0.0-1~35.16a26aa_armhf.deb
	rm openrov-geocamera-utils_1.0.0-1~35.16a26aa_armhf.deb

	# UVC Driver
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/uvcvideo/linux-4.4.30-ti-r65-uvcvideo-geopatch_1.0.0-1~31.1b7bcb8_armhf.deb
  	dpkg -i linux-4.4.30-ti-r65-uvcvideo-geopatch_1.0.0-1~31.1b7bcb8_armhf.deb
	rm linux-4.4.30-ti-r65-uvcvideo-geopatch_1.0.0-1~31.1b7bcb8_armhf.deb

	# v4l-utils
	deb_url="http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/gitlab/armhf/v4l-utils"
	deb_package="v4l-utils_1.10.1_armhf.deb"
	install_dep_from_url

	# Geomuxpp App
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/gitlab/armhf/geomuxpp/geomuxpp_1.0.1_armhf.deb
	dpkg -i geomuxpp_1.0.1_armhf.deb
	rm geomuxpp_1.0.1_armhf.deb

	# Arduino Core
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/arduino/openrov-arduino_1.0.0-1~21_armhf.deb && \
	dpkg -i openrov-arduino_1.0.0-1~21_armhf.deb && \
	rm openrov-arduino_1.0.0-1~21_armhf.deb

	# Arduino Builder
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/arduino-builder/openrov-arduino-builder_1.0.0-1~6_armhf.deb
	dpkg -i openrov-arduino-builder_1.0.0-1~6_armhf.deb
	rm openrov-arduino-builder_1.0.0-1~6_armhf.deb

	# Nightrider program
	deb_url="http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/gitlab/armhf/bbb-ledstatus"
	deb_package="bbb-ledstatus_1.0.0_armhf.deb"
	install_dep_from_url
	
	# Mjpeg Streamer dependencies
	deb_url="http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/gitlab/armhf/libjpeg-turbo"
	deb_package="libjpeg-turbo_1.5.0_armhf.deb"
	install_dep_from_url

	deb_url="http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/gitlab/armhf/libuv"
	deb_package="libuv_1.1.0_armhf.deb"
	install_dep_from_url

	deb_url="http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/gitlab/armhf/uwebsockets"
	deb_package="uwebsockets_0.11.0_armhf.deb"
	install_dep_from_url

	# MjpgStreamer App
	deb_url="http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/gitlab/armhf/mjpg-streamer"
	deb_package="mjpg-streamer_1.1.0_armhf.deb"
	install_dep_from_url
}
install_node_pkgs () {
	if [ -f /usr/bin/npm ] ; then
		cd /
		echo "Upgrading NPM"
		# https://github.com/rcn-ee/repos/issues/5#issuecomment-181610810
		npm install npm -g
		echo "Installing npm packages"
		echo "debug: node: [`nodejs --version`]"

		if [ -f /usr/local/bin/npm ] ; then
			npm_bin="/usr/local/bin/npm"
		else
			npm_bin="/usr/bin/npm"
		fi

		echo "debug: npm: [`${npm_bin} --version`]"

		#export npm_config_global=true		

		#c9-core-installer...
		${npm_bin} config delete cache
		${npm_bin} config delete tmp
		${npm_bin} config delete python

		#fix npm in chroot.. (did i mention i hate npm...)
		if [ ! -d /root/.npm ] ; then
			mkdir -p /root/.npm
		fi
		${npm_bin} config set cache /root/.npm
		${npm_bin} config set group 0
		${npm_bin} config set init-module /root/.npm-init.js

		if [ ! -d /root/tmp ] ; then
			mkdir -p /root/tmp
		fi
		${npm_bin} config set tmp /root/tmp
		${npm_bin} config set user 0
		${npm_bin} config set userconfig /root/.npmrc

		# Sysdetect
		git_repo="https://github.com/openrov-dev/orov-sysdetect.git"
		git_target_dir="/opt/openrov/system"
		if [ "$MYENV" = "production" ]
		then
			git_branch="v31.0.0-release"
		else
	  		git_branch="master"
		fi		
		git_clone_branch
		if [ -f ${git_target_dir}/.git/config ] ; then
			cd ${git_target_dir}/
			TERM=dumb npm install --unsafe-perm 

			wfile="/lib/systemd/system/orov-sysdetect.service"
			echo "[Unit]" > ${wfile}
			echo "Description=OpenROV System Detection Process" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Service]" >> ${wfile}
			echo "Type=oneshot" >> ${wfile}
			echo "NonBlocking=True" >> ${wfile}
			echo "WorkingDirectory=/opt/openrov/system" >> ${wfile}
			echo "ExecStart=/usr/bin/node src/index.js" >> ${wfile}
			echo "SyslogIdentifier=orov-sysdetect" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Install]" >> ${wfile}
			echo "WantedBy=orov-cockpit.service" >> ${wfile}

			systemctl enable orov-sysdetect.service || true
		fi

		# Cockpit
		git_repo="https://github.com/OpenROV/openrov-cockpit"
		git_target_dir="/opt/openrov/cockpit"
		if [ "$MYENV" = "production" ]
		then
			git_branch="v31.0.0-RC1"
		else
	  		git_branch="master"
		fi	
		git_clone_branch
		if [ -f ${git_target_dir}/.git/config ] ; then
			cd ${git_target_dir}/
			#These are the setting for the deploy:dev-image, change when deploying prod-image
			TERM=dumb npm run-script build:dev

			wfile="/lib/systemd/system/orov-cockpit.service"
			echo "[Unit]" > ${wfile}
			echo "Description=Cockpit server" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Service]" >> ${wfile}

			# Set restart on the prod-image
			if [ "$MYENV" = "production" ]
			then
			  echo "Restart=always" >> ${wfile}
			fi
			#Temporariy add for first load debugging
			echo "Environment=DEBUG=*:error,error:*"  >> ${wfile}			
			echo "NonBlocking=True" >> ${wfile}
			echo "WorkingDirectory=/opt/openrov/cockpit/src" >> ${wfile}
			echo "ExecStart=/usr/bin/node cockpit.js" >> ${wfile}
			echo "SyslogIdentifier=orov-cockpit" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Install]" >> ${wfile}
			echo "WantedBy=multi-user.target" >> ${wfile}

			systemctl enable orov-cockpit.service || true

			bash install_lib/openrov-cockpit-afterinstall.sh
		fi

		# Proxy
		git_repo="https://github.com/openrov/openrov-proxy"
		git_target_dir="/opt/openrov/openrov-proxy"
		if [ "$MYENV" = "production" ]
		then
			git_branch="v1.2.0"
		else
	  		git_branch="master"
		fi	
		git_clone_branch
		if [ -f ${git_target_dir}/.git/config ] ; then
			cd ${git_target_dir}/
			TERM=dumb npm install --production
			cd proxy-via-browser
			TERM=dumb npm install --production
			cd ${git_target_dir}/
			#bash install_lib/openrov-proxy-afterinstall.sh
			ln -s /opt/openrov/openrov-proxy/proxy-via-browser/ /opt/openrov/proxy
			mkdir -p /etc/nginx/locations-enabled
			ln -s /opt/openrov/proxy/nginx.location /etc/nginx/locations-enabled/proxy.conf	
			
			wfile="/lib/systemd/system/orov-proxy.service"
			echo "[Unit]" > ${wfile}
			echo "Description=OpenROV Proxy Service" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Service]" >> ${wfile}

			# Set restart on the prod-image
			if [ "$MYENV" = "production" ]
			then
			  echo "Restart=always" >> ${wfile}
			fi			
			echo "NonBlocking=True" >> ${wfile}
			echo "WorkingDirectory=/opt/openrov/proxy" >> ${wfile}
			echo "ExecStartPre=/opt/openrov/proxy/pre-start.sh" >> ${wfile}
			echo "ExecStart=/usr/bin/node index.js" >> ${wfile}
			echo "ExecStopPost=/opt/openrov/proxy/pre-stop.sh" >> ${wfile}			
			echo "SyslogIdentifier=orov-proxy" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Install]" >> ${wfile}
			echo "WantedBy=multi-user.target" >> ${wfile}

			#Temporarily disabled https://github.com/OpenROV/openrov-software/issues/513
			#systemctl enable orov-proxy.service || true

		fi


		echo "Installing wetty"
		if [ "$MYENV" = "production" ]
		then
			TERM=dumb npm install -g wetty@0.2.0
		else
	  		TERM=dumb npm install -g wetty
		fi

		mkdir -p /etc/nginx/locations-enabled
		wfile="/etc/nginx/locations-enabled/wetty.conf"

		echo "location /wetty {" > ${wfile}
		echo "	proxy_pass http://127.0.0.1:3009/wetty;" >> ${wfile}
		echo "	proxy_http_version 1.1;" >> ${wfile}
		echo '	proxy_set_header Upgrade $http_upgrade;' >> ${wfile}
		echo "	proxy_set_header Connection "upgrade";" >> ${wfile}
		echo "" >> ${wfile}
		echo '	proxy_set_header X-Real-IP $remote_addr;' >> ${wfile}
		echo '	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;' >> ${wfile}
		echo '	proxy_set_header Host $http_host;' >> ${wfile}
		echo "	proxy_set_header X-NginX-Proxy true;" >> ${wfile}
		echo "}" >> ${wfile}

		cd /opt/

		#cloud9 installed by cloud9-installer
		if [ -d /opt/cloud9/build/standalonebuild ] ; then
			if [ -f /usr/bin/make ] ; then
				echo "Installing winston"
				if [ "$MYENV" = "production" ]
				then
					TERM=dumb npm install -g winston@2.2.0 --arch=armhf
				else
					TERM=dumb npm install -g winston --arch=armhf
				fi				
				
			fi

			#cloud9 conflicts with the openrov proxy, move cloud 9
			if [ -f /lib/systemd/system/cloud9.socket ] ; then
				sed -i -e 's:3000:3131:g' /lib/systemd/system/cloud9.socket
			fi

			systemctl enable cloud9.socket || true
			systemctl start cloud9.socket || true
		fi

		cleanup_npm_cache
		sync
    cd /
	fi
}

install_git_repos ()
{
	# MCU Firmware
	git_repo="https://github.com/openrov/openrov-software-arduino"
	if [ "$MYENV" = "production" ]
	then
		git_branch="v31.0.0-release"
	else
		git_branch="master"
	fi	
	git_target_chroot_dir="/opt/openrov/firmware"
	git_target_dir="${ROOTFS_DIR}${git_target_chroot_dir}"
	git_clone_branch

	# DTB Redbuilder
	git_repo="https://github.com/RobertCNelson/dtb-rebuilder.git"
	git_branch="4.4-ti"	
	git_target_dir="/opt/source/dtb-${git_branch}"
	git_clone_branch

## The git check out is depth 1, which is probably why reset does not work
#	if [ "$MYENV" = "production" ]
#	then
#		cd ${git_target_dir}/
#		git reset --hard 7a48c85b3d3aef794b3eecfe201f4db3ff416d15
#	fi	

	# The beaglboard examples are now also adding 4.9-ti for dtd-rebuilder?

	# BBB DTOverlays
	git_repo="https://github.com/beagleboard/bb.org-overlays"
	git_target_dir="/opt/source/bb.org-overlays"
	git_branch="master"	
	git_clone_branch

# This is failing at the moment.
#	if [ "$MYENV" = "production" ]
#	then
#		cd ${git_target_dir}/
#		git reset --hard 961e2ee94bde68f2a5602a93419a2bb36270eea2
#	fi

	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		if [ ! "x${repo_rcnee_pkg_version}" = "x" ] ; then
			is_kernel=$(echo ${repo_rcnee_pkg_version} | grep 4.1 || true)
			if [ ! "x${is_kernel}" = "x" ] ; then
				if [ -f /usr/bin/make ] ; then
					if [ ! -f /lib/firmware/BB-ADC-00A0.dtbo ] ; then
						make
						make install
						make clean
					fi
					update-initramfs -u -k ${repo_rcnee_pkg_version}
					make clean
				fi
			fi
		fi
		cd /
	fi

	# Image customization
	git_repo="https://github.com/openrov/openrov-image-customization"
	git_target_dir="/opt/openrov/image-customization"
	if [ "$MYENV" = "production" ]
	then
		git_branch="v31.0.0-release"
	else
		git_branch="bbb-jessie"	
	fi	
	git_clone_branch
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		./beforeinstall.sh || true
		./afterinstall.sh || true
	fi

}

patchdnsmasq () {
	if grep -q "network-online.target" /lib/systemd/system/dnsmasq.service;
	then
		echo "dnsmasq already patched"
	else
		echo "patching dnsmasq unit file"
		sed -i '/^\[Unit\]/a Wants=network-online.target\nAfter=network-online.target' /lib/systemd/system/dnsmasq.service
		systemctl daemon-reload	|| true
	fi
}

speedUpBootTime () {
	sed -i 's/Type=oneshot/Type=simple/g' /lib/systemd/system/generic-board-startup.service
	
	#This driver has been timing out during load
	#systemctl disable bb-wl18xx-tether.service	
}

todo () {
	#Setup nginx
	#cd /etc/nginx/sites-enabled/
	#cp /opt/openrov/image-customization/nginx/default default
	
	#We only need one logger, and journald seems to be it
	apt-get purge -y rsyslog
	patchdnsmasq
	speedUpBootTime
}

cleanup () {
	TERM=dumb npm cache clean
	rm -rf /tmp/*
	apt-get clean
	rm -rf /var/lib/apt/lists/*
	find /usr/share/doc -depth -type f ! -name copyright|xargs rm || true
	find /usr/share/doc -empty|xargs rmdir || true
	rm -rf /usr/share/man/* /usr/share/groff/* /usr/share/info/*
	rm -rf /usr/share/lintian/* /usr/share/linda/* /var/cache/man/*	
	rm -rf /home/rov/.cache
}

primefirstboot () {
	touch /var/.RESIZE_ROOT_PARTITION
}


is_this_qemu

install_custom_pkgs
install_node_pkgs
todo
cleanup
primefirstboot

if [ -f /usr/bin/git ] ; then
	git config --global user.email "${rfs_username}@example.com"
	git config --global user.name "${rfs_username}"
	install_git_repos
	git config --global --unset-all user.email
	git config --global --unset-all user.name
fi

if [ "$MYENV" = "production" ]
then
	echo "prod-build $IMG_VERSION" > /ROV-Suite-version
else
	echo "dev-build $IMG_VERSION" > /ROV-Suite-version	
fi

chown rov:rov /home -R
