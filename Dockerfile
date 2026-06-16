FROM eclipse-temurin:17-jdk-jammy AS build

WORKDIR /app

# Copy Gradle wrapper and config files first for better caching
COPY gradlew ./
COPY gradle ./gradle
COPY build.gradle.kts settings.gradle.kts gradle.properties ./

# Copy the .git directory for grgit version resolution
COPY .git ./.git

# Copy source code
COPY LavalinkServer ./LavalinkServer
COPY protocol ./protocol
COPY plugin-api ./plugin-api

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
