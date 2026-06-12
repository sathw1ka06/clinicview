# Stage 1: Build the Flutter Web App
FROM ghcr.io/cirruslabs/flutter:stable AS build-env
WORKDIR /app

# Trick Flutter into "Continuous Integration" mode so it NEVER asks for input
ENV CI=true
ENV FLUTTER_NO_ANALYTICS=true

# Prevent Git from throwing silent security warnings inside the container
RUN git config --global --add safe.directory '*'

# Copy all files
COPY . .

# Get packages and build
RUN flutter pub get
RUN flutter build web

# Stage 2: Serve with NGINX
FROM nginx:alpine
# Copy the built files from Stage 1 into NGINX
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]