# 📚 Swagger/OpenAPI Setup và Sử Dụng trên Ubuntu Server

## 🚀 Swagger đã được thiết lập sẵn

Dự án SkillVerse Backend đã được cấu hình sẵn Swagger/OpenAPI với:

### 📋 Dependencies đã có:
```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.8.11</version>
</dependency>
```

### ⚙️ Configuration:
- **SwaggerConfig.java**: Cấu hình OpenAPI với JWT authentication
- **Application.yml**: Endpoint configuration

## 🌐 Truy cập Swagger trên Ubuntu Server

### 1. 📡 URLs chính:

#### 🔗 Swagger UI (Giao diện web):
```bash
http://YOUR_SERVER_IP/api/swagger-ui/index.html
# hoặc
http://YOUR_DOMAIN/api/swagger-ui/index.html
```

#### 📄 OpenAPI JSON Specification:
```bash
http://YOUR_SERVER_IP/api/v3/api-docs
# hoặc  
http://YOUR_DOMAIN/api/v3/api-docs
```

#### 📄 OpenAPI YAML Specification:
```bash
http://YOUR_SERVER_IP/api/v3/api-docs.yaml
# hoặc
http://YOUR_DOMAIN/api/v3/api-docs.yaml
```

### 2. 🖥️ Truy cập qua SSH Tunnel (nếu server không public):

```bash
# Tạo SSH tunnel để truy cập Swagger từ máy local
ssh -L 8080:localhost:8080 username@your-server-ip

# Sau đó truy cập:
# http://localhost:8080/api/swagger-ui/index.html
```

### 3. 🔍 Kiểm tra trạng thái Swagger trên server:

```bash
# SSH vào server
ssh username@your-server-ip

# Kiểm tra container đang chạy
docker compose ps

# Kiểm tra logs backend
docker compose logs backend

# Test swagger endpoint
curl -I http://localhost:8080/api/swagger-ui/index.html
curl -I http://localhost:8080/api/v3/api-docs

# Kiểm tra từ bên ngoài
curl -I http://your-server-ip/api/swagger-ui/index.html
```

## 🛠️ Troubleshooting

### ❌ Không truy cập được Swagger:

1. **Kiểm tra container backend:**
```bash
docker compose logs backend --tail=50
```

2. **Kiểm tra port mapping:**
```bash
docker compose ps
# Đảm bảo backend port 8080 được map
```

3. **Kiểm tra nginx config:**
```bash
docker compose logs nginx --tail=50
```

4. **Test internal connectivity:**
```bash
# SSH vào server
docker compose exec backend curl http://localhost:8080/api/swagger-ui/index.html
```

### ⚙️ Fix thường gặp:

#### 1. Swagger không load:
```bash
# Restart backend service
docker compose restart backend

# Hoặc rebuild
docker compose up -d --build backend
```

#### 2. 403/404 errors:
```bash
# Kiểm tra nginx config
cat nginx/nginx.conf

# Restart nginx
docker compose restart nginx
```

#### 3. CORS issues:
```bash
# Kiểm tra CORS config trong SwaggerConfig.java
# Đảm bảo server URLs được cấu hình đúng
```

## 🔧 Cấu hình nâng cao

### 1. 🔐 Swagger với Authentication:

Swagger đã được cấu hình JWT Bearer token:

```java
.addSecurityItem(new SecurityRequirement().addList("Bearer Authentication"))
.components(new Components()
    .addSecuritySchemes("Bearer Authentication", new SecurityScheme()
        .type(SecurityScheme.Type.HTTP)
        .scheme("bearer")
        .bearerFormat("JWT")))
```

**Cách sử dụng:**
1. Đăng nhập qua API để lấy JWT token
2. Click "Authorize" trong Swagger UI  
3. Nhập: `Bearer YOUR_JWT_TOKEN`
4. Test các protected endpoints

### 2. 📊 Export OpenAPI Spec:

```bash
# Tải JSON spec
curl http://your-server/api/v3/api-docs > api-spec.json

# Tải YAML spec  
curl http://your-server/api/v3/api-docs.yaml > api-spec.yaml
```

### 3. 🔄 Auto-sync với postman:

```bash
# Import vào Postman
# File > Import > Link > http://your-server/api/v3/api-docs
```

## 📱 Mobile/Client Integration

### 1. 🤖 Generate client code:
```bash
# Sử dụng OpenAPI Generator
npx @openapitools/openapi-generator-cli generate \
  -i http://your-server/api/v3/api-docs \
  -g typescript-axios \
  -o ./src/api-client
```

### 2. 📝 Documentation:
```bash
# Generate HTML docs
npx redoc-cli build http://your-server/api/v3/api-docs
```

## 🎯 Testing với Swagger

### 1. 🧪 Test Flow:
1. **Authentication**: POST `/api/auth/login`
2. **Copy JWT token**
3. **Click "Authorize"** trong Swagger UI
4. **Paste token**: `Bearer YOUR_TOKEN`
5. **Test protected endpoints**

### 2. 📋 Common endpoints để test:
- `GET /api/health` - Health check
- `POST /api/auth/login` - Login
- `GET /api/auth/profile` - User profile
- `GET /api/courses` - List courses
- `POST /api/courses` - Create course

## 🔒 Production Security

### 1. 🛡️ Disable Swagger trong production:
```yaml
# application-prod.yml
springdoc:
  swagger-ui:
    enabled: false
  api-docs:
    enabled: false
```

### 2. 🔐 Restrict access:
```bash
# Chỉ cho phép truy cập từ admin IPs
# Cấu hình trong nginx.conf:
location /api/swagger-ui {
    allow 192.168.1.0/24;
    allow your-admin-ip;
    deny all;
    # ... proxy settings
}
```

## 📞 Quick Commands Reference

```bash
# Kiểm tra Swagger status
curl -s http://localhost/api/swagger-ui/index.html | grep -i swagger

# Download API docs
wget http://localhost/api/v3/api-docs -O api-docs.json

# Test với curl
curl -X POST http://localhost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Health check
curl http://localhost/api/health | jq .
```

## 🆘 Support Commands

```bash
# Full container restart
docker compose down && docker compose up -d

# Check all endpoints
docker compose exec backend curl -s http://localhost:8080/actuator/mappings | jq .

# View detailed logs
docker compose logs -f backend | grep -i swagger
```

---

## 📞 Contact & Issues

Nếu gặp vấn đề:
1. 📧 Check logs: `docker compose logs backend`
2. 🔍 Verify endpoints: `curl http://localhost/api/health`  
3. 🛠️ Restart services: `docker compose restart`
4. 📋 Check this guide: `/path/to/this/SWAGGER_SETUP_GUIDE.md`

**Happy API Testing! 🚀📚**