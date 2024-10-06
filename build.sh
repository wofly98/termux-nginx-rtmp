TERMUX_PKG_HOMEPAGE=https://www.nginx.org
TERMUX_PKG_DESCRIPTION="Lightweight HTTP server"
TERMUX_PKG_LICENSE="BSD 2-Clause"
TERMUX_PKG_MAINTAINER="@muxfd"
TERMUX_PKG_DEPENDS="libandroid-glob, libcrypt, pcre, openssl, zlib"
TERMUX_PKG_VERSION="1.25.1"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_SERVICE_SCRIPT=("nginx" 'mkdir -p ~/.nginx\nif [ -f "$HOME/.nginx/nginx.conf" ]; then CONFIG="$HOME/.nginx/nginx.conf"; else CONFIG="$PREFIX/etc/nginx/nginx.conf"; fi\nexec nginx -p ~/.nginx -g "daemon off;" -c $CONFIG 2>&1')
TERMUX_PKG_CONFFILES="
etc/nginx/fastcgi.conf
etc/nginx/fastcgi_params
etc/nginx/koi-win
etc/nginx/koi-utf
etc/nginx/mime.types
etc/nginx/nginx.conf
etc/nginx/scgi_params
etc/nginx/uwsgi_params
etc/nginx/win-utf"

termux_step_get_source() {
        mkdir -p $TERMUX_PKG_SRCDIR
}

termux_step_post_get_source() {
        cd $TERMUX_PKG_SRCDIR

        tar xvfz newngx.tgz -C $TERMUX_PKG_SRCDIR

}

termux_step_pre_configure() {
	# Certain packages are not safe to build on device because their
	# build.sh script deletes specific files in $TERMUX_PREFIX.
	if $TERMUX_ON_DEVICE_BUILD; then
		termux_error_exit "Package '$TERMUX_PKG_NAME' is not safe for on-device builds."
	fi

	CPPFLAGS="$CPPFLAGS -DIOV_MAX=1024"
	LDFLAGS="$LDFLAGS -landroid-glob"

	# remove config from previous installs
	rm -rf "$TERMUX_PREFIX/etc/nginx"
}

termux_step_configure() {
	DEBUG_FLAG=""
	$TERMUX_DEBUG && DEBUG_FLAG="--with-debug"

	./configure \
		--prefix=/data/data/com.termux/files/home/ngx \
		--crossbuild="Linux:3.16.1:$TERMUX_ARCH" \
		--crossfile="$TERMUX_PKG_SRCDIR/auto/cross/Android" \
		--with-cc=$CC \
		--with-cpp=$CPP \
		--with-cc-opt="$CPPFLAGS $CFLAGS" \
		--with-ld-opt="$LDFLAGS" \
		--with-pcre \
		--with-pcre-jit \
		--with-threads \
		--with-ipv6 \
    --sbin-path=sbin/juno_ngx \
    --conf-path=conf/juno_ngx.conf \
    --http-log-path=logs/proxy_access.log \
    --pid-path=sbin/.juno_ngx.pid \
    --lock-path=sbin/.juno_ngx.lock \
    --error-log-path=logs/proxy_error.log \
		--http-client-body-temp-path="$TERMUX_PREFIX/var/lib/nginx/client-body" \
		--http-proxy-temp-path="$TERMUX_PREFIX/var/lib/nginx/proxy" \
		--http-fastcgi-temp-path="$TERMUX_PREFIX/var/lib/nginx/fastcgi" \
		--http-scgi-temp-path="$TERMUX_PREFIX/var/lib/nginx/scgi" \
		--http-uwsgi-temp-path="$TERMUX_PREFIX/var/lib/nginx/uwsgi" \
    --add-dynamic-module=./modules/vts \
    --add-dynamic-module=./modules/purge \
    --add-dynamic-module=./modules/sorted_args \
		--with-http_auth_request_module \
		--with-http_ssl_module \
		--with-http_v2_module \
		--with-http_gunzip_module \

    --with-file-aio \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_gzip_static_module \
    --with-http_slice_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_degradation_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
		$DEBUG_FLAG
}

termux_step_post_make_install() {
	# many parts are taken directly from Arch PKGBUILD
	# https://git.archlinux.org/svntogit/packages.git/tree/trunk/PKGBUILD?h=packages/nginx



}

termux_step_post_massage() {
	# keep empty dirs which were deleted in massage
	mkdir -p "$TERMUX_PKG_MASSAGEDIR/$TERMUX_PREFIX/var/log/nginx"
	for dir in client-body proxy fastcgi scgi uwsgi; do
		mkdir -p "$TERMUX_PKG_MASSAGEDIR/$TERMUX_PREFIX/var/lib/nginx/$dir"
	done
}
