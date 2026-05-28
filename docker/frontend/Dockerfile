# 1단계: 빌드 (Node.js 사용)
FROM node:22-alpine AS build
WORKDIR /app

# 라이브러리 설치 단계 캐싱 (package.json 사용)
COPY package.json package-lock.json ./
RUN npm install

# 소스 코드 복사 및 빌드
COPY . .
RUN npm run build

# 2단계: 실행 (Nginx 사용으로 가볍고 빠르게)
FROM nginx:stable-alpine

# 빌드 결과물을 Nginx가 서비스할 폴더로 복사
COPY docker/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

# 기본 80포트 개방
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]