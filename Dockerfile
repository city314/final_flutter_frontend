# Stage 1: Build Flutter Web
FROM cirrusci/flutter:3.19.6 AS flutterbuilder

WORKDIR /app
# Chỉ copy pubspec để tận dụng cache nếu không đổi dependency
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy toàn bộ source và build web
COPY . .
RUN flutter build web --release

# Stage 2: Serve với nginx
FROM nginx:1.25.3-alpine

# Copy toàn bộ kết quả build từ stage trước
COPY --from=flutterbuilder /app/build/web /usr/share/nginx/html

EXPOSE 80
