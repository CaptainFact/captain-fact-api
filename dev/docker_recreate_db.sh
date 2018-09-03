docker stop cf_dev_db
docker rm cf_dev_db
docker run -d --name cf_dev_db -p 5432:5432 captainfact/dev-db:latest
