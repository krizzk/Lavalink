FROM eclipse-temurin:17-jdk-jammy AS build

WORKDIR /app

# Install git for grgit plugin
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*

# Copy Gradle wrapper and config files first for better caching
COPY gradlew ./
COPY gradle ./gradle
COPY build.gradle.kts settings.gradle.kts gradle.properties ./

# Copy source code
COPY LavalinkServer ./LavalinkServer
COPY protocol ./protocol
COPY plugin-api ./plugin-api

# Create a synthetic .git repo for grgit version resolution
# (Railway excludes .git from the build context)
RUN git init \
    && git config user.email "build@railway.app" \
    && git config user.name "Railway Build" \
    && git add -A \
    && git commit -m "build"

# Build the project
RUN chmod +x gradlew && ./gradlew :Lavalink-Server:bootJar -x check -x test -Pproduction

# Runtime stage
FROM eclipse-temurin:17-jre-jammy

WORKDIR /opt/Lavalink

RUN groupadd -g 322 lavalink && \
    useradd -r -u 322 -g lavalink lavalink && \
    chown -R lavalink:lavalink /opt/Lavalink

USER lavalink

COPY --from=build /app/LavalinkServer/build/libs/Lavalink.jar Lavalink.jar
COPY LavalinkServer/application.yml application.yml

ENTRYPOINT ["java", "-jar", "Lavalink.jar"]
