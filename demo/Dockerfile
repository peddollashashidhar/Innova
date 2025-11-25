## Multi-stage Dockerfile for building and running the Spring Boot app

# ---------- Builder: build the fat jar with Gradle (uses Gradle wrapper)
FROM gradle:9.2.1-jdk21 AS builder
WORKDIR /home/gradle/project

# Copy Gradle wrapper and build files first to leverage Docker layer cache
COPY --chown=gradle:gradle gradle/ gradle/
COPY --chown=gradle:gradle gradlew gradlew.bat build.gradle settings.gradle ./
RUN chmod +x ./gradlew

# Copy the rest of the project and build the application (skip tests for container builds)
COPY --chown=gradle:gradle . .
RUN ./gradlew --no-daemon clean bootJar -x test


# ---------- Runtime: small JRE image
FROM eclipse-temurin:21-jre AS runtime

# Create a non-root user for running the app
RUN addgroup --system app && adduser --system --ingroup app app || true
WORKDIR /app

# Copy built jar from the builder stage
COPY --from=builder /home/gradle/project/build/libs/*.jar /app/app.jar
RUN chown app:app /app/app.jar || true

# Run as non-root user
USER app


# Allow overriding JVM options at runtime via JAVA_OPTS
ENV JAVA_OPTS="-XX:+UseContainerSupport -Xms256m -Xmx512m"

# Set Spring Boot server port inside the container and expose that port
ENV SERVER_PORT=8081
EXPOSE 8081

# Use exec form so signals are forwarded correctly; allow JAVA_OPTS to be passed in
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]