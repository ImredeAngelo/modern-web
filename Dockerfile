# ======
# Build Nginx from source
# ======
FROM alpine AS build-nginx
ARG NGINX_VERSION=1.25.1

RUN apk update
RUN apk --update add git make g++ zlib-dev linux-headers pcre-dev openssl-dev \
						cmake 

# Get Nginx source code
WORKDIR /home
RUN wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
RUN tar xvf nginx-$NGINX_VERSION.tar.gz

# Enable brotli compression
WORKDIR /home
RUN git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli
WORKDIR /home/ngx_brotli/deps/brotli/out
RUN cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..
RUN cmake --build . --config Release --target brotlienc

# Use SSL with QUIC support
# RUN git clone https://github.com/quictls/openssl
WORKDIR /home/quictls
COPY vendors/openssl .

# Build Nginx from source (flags from brotli install instructions)
WORKDIR /home/nginx-$NGINX_VERSION
RUN export CFLAGS="-m64 -march=native -mtune=native -Ofast -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections"
RUN export LDFLAGS="-m64 -Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections"
RUN ./configure \
	--add-module=/home/ngx_brotli \
	--prefix=/etc/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--sbin-path=/usr/sbin/nginx \
	--with-debug \
	--with-http_gzip_static_module \
	--with-http_v2_module \
    --with-http_v3_module \
	--with-cc-opt="-I../quictls/build/include" \
    --with-ld-opt="-L../quictls/build/lib"
RUN make && make install

# Logs
WORKDIR /var/log/nginx
RUN touch /var/log/nginx/error.log
RUN touch /var/log/nginx/access.log

# Config
WORKDIR /etc/nginx
COPY services/nginx/nginx.conf nginx.conf
COPY services/nginx/conf.d conf.d



# ======
# Build web app
# ======
FROM node:lts AS build-app

# RUN apt-get install brotli

WORKDIR /usr/app
ADD ./services/app .
RUN yarn install
RUN yarn build
RUN gzip -9k dist/*.* dist/assets/*.*



# ======
# Only include necessary files
# ======
FROM alpine AS production

RUN apk update
RUN apk add openssl brotli pcre

# Static files
WORKDIR /etc/nginx/data
COPY --from=build-app /usr/app/dist .
RUN brotli -k -Z *.* assets/*.*
RUN rm *.gz.br

# Nginx
WORKDIR /etc/nginx
COPY --from=build-nginx /etc/nginx .
COPY --from=build-nginx /usr/sbin/nginx /usr/sbin/nginx
COPY --from=build-nginx /var/log/nginx /var/log/nginx

# RUN ln -sf /dev/stdout /etc/nginx/logs/access.log
RUN ln -sf /dev/stdout /var/log/nginx/access.log 
RUN ln -sf /dev/stderr /var/log/nginx/error.log 

# Startup
WORKDIR /
CMD ["nginx", "-g", "daemon off;"]



# ======
# Development build with localhost certificates
# ======
FROM production AS development

# SSL certificates
# TODO: Only for development build
WORKDIR /etc/nginx/certs
RUN openssl req -x509 -out localhost.com.crt -keyout localhost.com.key \
			-newkey rsa:2048 -nodes -sha256 \
			-subj '/CN=localhost' -extensions EXT -config <( \
			printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")