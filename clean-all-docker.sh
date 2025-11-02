#!/bin/bash
echo "🧹 Cleaning up Docker Swarm..."

# 1. Remove all stacks
for s in $(docker stack ls --format '{{.Name}}'); do
  echo "Removing stack: $s"
  docker stack rm "$s"
done

# Wait a few seconds for stack cleanup
sleep 5

# 2. Remove leftover services
if [ -n "$(docker service ls -q)" ]; then
  echo "Removing remaining services..."
  docker service rm $(docker service ls -q)
fi

# 3. Remove all containers
if [ -n "$(docker ps -aq)" ]; then
  echo "Removing all containers..."
  docker rm -f $(docker ps -aq)
fi

# 4. Remove ALL volumes (not just unused)
if [ -n "$(docker volume ls -q)" ]; then
  echo "Removing all volumes..."
  docker volume rm $(docker volume ls -q)
fi

# 5. Remove unused networks (keeps Swarm networks intact)
echo "Removing unused networks..."
docker network prune -f

# 6. Remove dangling images and cache
echo "Removing unused images and cache..."
docker system prune -af --volumes

# 7. Final check
echo "✅ Final status:"
echo "Stacks:"
docker stack ls
echo
echo "Services:"
docker service ls
echo
echo "Containers:"
docker ps -a
echo
echo "Networks:"
docker network ls
echo
echo "Volumes:"
docker volume ls
echo
echo "Images:"
docker images
echo
echo "✅ Docker Swarm cleanup complete!"
