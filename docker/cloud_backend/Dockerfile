FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

COPY . .

RUN ./gradlew dependencies

RUN ./gradlew clean build

EXPOSE 8080

CMD [ "java", "-jar", "build/libs/ChatApp-0.0.1-SNAPSHOT.jar" ]
