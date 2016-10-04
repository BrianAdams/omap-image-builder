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

export LC_ALL=C

u_boot_release="v2016.01"
u_boot_release_x15="v2015.07"
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
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/zmq/openrov-zmq_1.0.0-1~2_armhf.deb
	dpkg -i openrov-zmq_1.0.0-1~2_armhf.deb
	rm openrov-zmq_1.0.0-1~2_armhf.deb

	# GC6500 Apps
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/geocamera-libs/openrov-geocamera-utils_1.0.0-1~35.16a26aa_armhf.deb
	dpkg -i openrov-geocamera-utils_1.0.0-1~35.16a26aa_armhf.deb
	rm openrov-geocamera-utils_1.0.0-1~35.16a26aa_armhf.deb

	# UVC Driver
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/uvcvideo/linux-4.1.22-ti-r59-uvcvideo-geopatch_1.0.0-1~17.0012e33_armhf.deb
  	dpkg -i linux-4.1.22-ti-r59-uvcvideo-geopatch_1.0.0-1~17.0012e33_armhf.deb
	rm linux-4.1.22-ti-r59-uvcvideo-geopatch_1.0.0-1~17.0012e33_armhf.deb

	# Geomuxpp App
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/geomuxpp/openrov-geomuxpp_1.0.0-1~14_armhf.deb
	dpkg -i openrov-geomuxpp_1.0.0-1~14_armhf.deb
	rm openrov-geomuxpp_1.0.0-1~14_armhf.deb

	# Arduino Core
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/arduino/openrov-arduino_1.0.0-1~17_armhf.deb
	dpkg -i openrov-arduino_1.0.0-1~17_armhf.deb
	rm openrov-arduino_1.0.0-1~17_armhf.deb

	# Arduino Builder
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/arduino-builder/openrov-arduino-builder_1.0.0-1~6_armhf.deb
	dpkg -i openrov-arduino-builder_1.0.0-1~6_armhf.deb
	rm openrov-arduino-builder_1.0.0-1~6_armhf.deb

    # ZeroMQ for dynamiclly linking with MjpgStreamer App
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/zmq/openrov-zmq_1.0.0-1~2_armhf.deb
	dpkg -i openrov-zmq_1.0.0-1~2_armhf.deb
	rm openrov-zmq_1.0.0-1~2_armhf.deb	
	
	# MjpgStreamer App
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/mjpeg-streamer/openrov-mjpeg-streamer_2.0.1-10~27.27ae33f_armhf.deb	
	dpkg -i openrov-mjpeg-streamer_2.0.1-10~27.27ae33f_armhf.deb	
	rm openrov-mjpeg-streamer_2.0.1-10~27.27ae33f_armhf.deb	
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
	  	git_branch="master"
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
	  	git_branch="master"
		git_clone_branch
		if [ -f ${git_target_dir}/.git/config ] ; then
			cd ${git_target_dir}/
			TERM=dumb npm install --production --unsafe-perm

			wfile="/lib/systemd/system/orov-cockpit.service"
			echo "[Unit]" > ${wfile}
			echo "Description=Cockpit server" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Service]" >> ${wfile}
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

		# Dashboard
		git_repo="https://github.com/openrov/openrov-dashboard"
		git_target_dir="/opt/openrov/dashboard"
		git_clone_full
		if [ -f ${git_target_dir}/.git/config ] ; then
			cd ${git_target_dir}/
			TERM=dumb npm install --production --unsafe-perm
			TERM=dumb npm run-script bower
			wfile="/lib/systemd/system/orov-dashboard.socket"
			echo "[Socket]" > ${wfile}
			echo "ListenStream=3080" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Install]" >> ${wfile}
			echo "WantedBy=sockets.target" >> ${wfile}

			wfile="/lib/systemd/system/orov-dashboard.service"
			echo "[Unit]" > ${wfile}
			echo "Description=Cockpit server" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Service]" >> ${wfile}
			#http://stackoverflow.com/questions/22498753/no-data-from-socket-activation-with-systemd
			echo "NonBlocking=True" >> ${wfile}
			echo "WorkingDirectory=/opt/openrov/dashboard/src" >> ${wfile}
			echo "ExecStart=/usr/bin/node dashboard.js" >> ${wfile}
			echo "SyslogIdentifier=orov-dashboard" >> ${wfile}

			systemctl enable orov-dashboard.socket || true

		fi

		# Proxy
		git_repo="https://github.com/openrov/openrov-proxy"
		git_target_dir="/opt/openrov/openrov-proxy"
		git_clone_full
		if [ -f ${git_target_dir}/.git/config ] ; then
			cd ${git_target_dir}/
			TERM=dumb npm install --production
			cd proxy-via-browser
			TERM=dumb npm install --production
			cd ${git_target_dir}/
			ln -s /opt/openrov/openrov-proxy/proxy-via-browser/ /opt/openrov/proxy
			bash install_lib/openrov-proxy-afterinstall.sh
		fi


		echo "Installing wetty"
		TERM=dumb npm install -g wetty

		cd /opt/

		#cloud9 installed by cloud9-installer
		if [ -d /opt/cloud9/build/standalonebuild ] ; then
			if [ -f /usr/bin/make ] ; then
				echo "Installing winston"
				TERM=dumb npm install -g winston --arch=armhf
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
	git_branch="firmware-2.0"
	git_target_chroot_dir="/opt/openrov/firmware"
	git_target_dir="${ROOTFS_DIR}${git_target_chroot_dir}"
	git_clone_branch

	# DTB Redbuilder
	git_repo="https://github.com/RobertCNelson/dtb-rebuilder.git"
	git_branch="4.1-ti"
	git_target_dir="/opt/source/dtb-${git_branch}"
	git_clone_branch

	# BBB DTOverlays
	git_repo="https://github.com/beagleboard/bb.org-overlays"
	git_target_dir="/opt/source/bb.org-overlays"
	git_clone
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		if [ ! "x${repo_rcnee_pkg_version}" = "x" ] ; then
			is_kernel=$(echo ${repo_rcnee_pkg_version} | grep 4.1 || true)
			if [ ! "x${is_kernel}" = "x" ] ; then
				if [ -f /usr/bin/make ] ; then
					./dtc-overlay.sh
					make
					make install
					update-initramfs -u -k ${repo_rcnee_pkg_version}
					rm -rf /home/${rfs_username}/git/ || true
					make clean
				fi
			fi
		fi
		cd /
	fi

	# Image customization
	git_repo="https://github.com/openrov/openrov-image-customization"
	git_target_dir="/opt/openrov/image-customization"
	git_branch="bbb-jessie"
	git_clone_branch
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		./beforeinstall.sh || true
		./afterinstall.sh || true
	fi

}

todo () {
	#Setup nginx
	#cd /etc/nginx/sites-enabled/
	#cp /opt/openrov/image-customization/nginx/default default
	
	#We only need one logger, and journald seems to be it
	apt-get purge -y rsyslog
}


is_this_qemu

install_custom_pkgs
install_node_pkgs
todo

if [ -f /usr/bin/git ] ; then
	git config --global user.email "${rfs_username}@example.com"
	git config --global user.name "${rfs_username}"
	install_git_repos
	git config --global --unset-all user.email
	git config --global --unset-all user.name
fi

chown rov:rov /home -R
