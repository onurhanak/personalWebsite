This is my personal site built with Hugo, containerized with Docker, and hosted on AWS EC2. An Nginx reverse proxy handles incoming traffic, with HTTPS enabled via Certbot. GitHub Actions handles CI/CD—on every push to the main branch, it rebuilds the Docker image and redeploys it to EC2.

