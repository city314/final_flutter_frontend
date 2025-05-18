# Dockerfile (1 stage)
FROM node:20-alpine

# Cài http-server
RUN npm install -g http-server

# Tạo thư mục làm việc
WORKDIR /app

# Copy toàn bộ project
COPY . .

# Cài Flutter SDK (có thể dùng base image nếu cần)
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.6-stable.tar.xz && \
    tar xf flutter_linux_3.19.6-stable.tar.xz && \
    mv flutter /opt/flutter && \
    /opt/flutter/bin/flutter doctor

# Build Flutter web
RUN /opt/flutter/bin/flutter build web

# Dùng http-server để serve build
WORKDIR /app/build/web
EXPOSE 8080
CMD ["http-server", "-p", "8080"]
