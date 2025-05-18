# client/Dockerfile

# Stage build Flutter
FROM nginx:1.25.3-alpine

WORKDIR /app

# Copy các file cần thiết
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy toàn bộ project vào thư mục làm việc
COPY . .

# Build Flutter web
RUN flutter build web --release

# Stage deploy lên nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html

# Mở cổng 80 để truy cập web
EXPOSE 80
