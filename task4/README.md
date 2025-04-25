# Blog 
## 基础环境

**基础依赖:**
* go 1.21.10
* mysql

**服务配置:**
请修改cfg.json

**服务运行**
```bash
 go run main.go
```

## 测试用例

**用户注册**

```bash
curl --location 'http://localhost:9000/api/register' \
--header 'Content-Type: application/json' \
--data-raw '{
    "email":"tyler@gmail.com",
    "username":"tyler",
    "password":"123456"
}'
```

status: 200
```json
{"message":"User registered successfully"}
```


**用户登录**
```bash
curl --location 'http://localhost:9000/api/login' \
--header 'Content-Type: application/json' \
--data '{
    "username":"tyler",
    "password":"123456"
}'
```
status: 200
```json
{
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDU2NTAxOTksImlkIjoxLCJ1c2VybmFtZSI6InR5bGVyIn0.ps30LI7Ax3zdQaV5dcLb6BKenPs7tQxCFxFw9K2AZi4"
}
```

**创建帖子**
```bash
curl --location 'http://localhost:9000/api/posts/createPost' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDU2NDU3NTgsImlkIjoxLCJ1c2VybmFtZSI6InR5bGVyIn0.FsDc80h6LEol5IOVUx218vo__CEA2d7wggV1cnTI0x4' \
--data '{
    "title":"first post",
    "content":"is there anything i can do? ...."
}'
```
```json
{"id":1}
```

**查询全部帖子**
```bash
curl --location 'http://localhost:9000/api/posts/getPosts' \
--header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDU2NDU3NTgsImlkIjoxLCJ1c2VybmFtZSI6InR5bGVyIn0.FsDc80h6LEol5IOVUx218vo__CEA2d7wggV1cnTI0x4'
```

```json
[{"id":1,"title":"first post","content":"is there anything i can do? ....","created_at":1745563848}]
```

**获取帖子**
```bash
curl --location 'http://localhost:9000/api/posts/getPostByID?id=1' \
--header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDU2NDU3NTgsImlkIjoxLCJ1c2VybmFtZSI6InR5bGVyIn0.FsDc80h6LEol5IOVUx218vo__CEA2d7wggV1cnTI0x4'
```
```json
{"id":1,"title":"first post","content":"is there anything i can do? ....","created_at":1745563848}
```

**更新帖子**
```bash
curl --location 'http://localhost:9000/api/posts/updatePost' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDU2NDU3NTgsImlkIjoxLCJ1c2VybmFtZSI6InR5bGVyIn0.FsDc80h6LEol5IOVUx218vo__CEA2d7wggV1cnTI0x4' \
--data '{
    "id":1,
    "title":"new content",
    "content":"sorry,nothing is easy to do"
}'
```
```json
{"id":1,"message":"update success"}
```

**删除帖子**
```bash
curl --location 'http://localhost:9000/api/posts/deletePost' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDU2NDU3NTgsImlkIjoxLCJ1c2VybmFtZSI6InR5bGVyIn0.FsDc80h6LEol5IOVUx218vo__CEA2d7wggV1cnTI0x4' \
--data '{
    "id":1
}'
```
```json
{"id":1,"message":"delete success"}
```


**新增评论**
```bash
curl --location 'http://localhost:9000/api/comments/createComment' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDU2NDU3NTgsImlkIjoxLCJ1c2VybmFtZSI6InR5bGVyIn0.FsDc80h6LEol5IOVUx218vo__CEA2d7wggV1cnTI0x4' \
--data '{
    "post_id":2,
    "content":"is there anything i can do? ...."
}'
```
```json
{"id":1}
```

**查询帖子下的全部评论**
```bash
curl --location 'http://localhost:9000/api/comments/getPostComments?post_id=2' \
--header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDU2NDU3NTgsImlkIjoxLCJ1c2VybmFtZSI6InR5bGVyIn0.FsDc80h6LEol5IOVUx218vo__CEA2d7wggV1cnTI0x4' \
```
```json
[
  {
    "id": 1,
    "post_id": 0,
    "content": "is there anything i can do? ....",
    "created_at": 1745564148,
    "user": {
      "id": 1,
      "username": "tyler"
    }
  },
  {
    "id": 2,
    "post_id": 0,
    "content": "is there anything i can do? 1",
    "created_at": 1745564205,
    "user": {
      "id": 1,
      "username": "tyler"
    }
  },
  {
    "id": 3,
    "post_id": 0,
    "content": "is there anything i can do? 2",
    "created_at": 1745564209,
    "user": {
      "id": 1,
      "username": "tyler"
    }
  }
]
```