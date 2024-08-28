# Use Alpine as the base image
FROM alpine:latest

# Set environment variables
ENV TZ="US/Central" \
    # NGINX_CONF_URL="https://raw.githubusercontent.com/ComputerProsLLC/nginx_lancache/debian/etc/nginx/nginx.conf" \
    NETDATA_URL="https://my-netdata.io/kickstart.sh" 
    

# Install necessary packages, set timezone, and configure certificates
RUN apk update && \
    apk add --no-cache ca-certificates curl nginx nginx-mod-stream tzdata && \
    update-ca-certificates && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    update-ca-certificates && \
    mkdir -p /var/cache/nginx && \
    # curl -fsSL -o /etc/nginx/nginx.conf $NGINX_CONF_URL && \
    curl -fsSL $NETDATA_URL > /tmp/netdata-kickstart.sh && \
    sh /tmp/netdata-kickstart.sh --stable-channel --non-interactive --disable-telemetry && \
    chmod +x /opt/netdata/usr/lib/netdata/system/runit/run && \
    echo -e "jobs:\n- name: local\n  url: http://127.0.0.1:8080/nginx_status\n" > /opt/netdata/usr/lib/netdata/conf.d/go.d/nginx.conf

# Expose necessary ports
EXPOSE 80 19999

# Start NGINX and Netdata services
CMD ["sh", "-c", "nginx && /opt/netdata/usr/lib/netdata/system/runit/run && tail -f /dev/null"]
#CMD ["tail", "-f", "/dev/null"]