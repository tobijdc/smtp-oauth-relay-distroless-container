# Use an official Python runtime as a parent image
FROM python:3.13.15-slim-trixie AS build-env

# Set the working directory in the container
WORKDIR /usr/src/smtp-relay/

# Copy the requirements file into the container at /usr/src/smtp-relay/
COPY ./requirements.txt .

# Install any needed packages specified in requirements.txt
RUN apt-get update \
   && apt-get install ca-certificates \
   && pip install --no-cache-dir --user -r requirements.txt \
   && find /root/.local/ -type d -a -name test -o -name tests -exec rm -rf '{}' \+

# Copy the src contents into the container
COPY ./src .

# Run main.py when the container launches
#CMD ["python", "main.py"]

FROM gcr.io/distroless/python3-debian13:nonroot
COPY --from=build-env --chown=nonroot:nonroot /usr/src/smtp-relay/ /usr/src/smtp-relay/
COPY --from=build-env --chown=nonroot:nonroot /root/.local/ /home/nonroot/.local/

WORKDIR /usr/src/smtp-relay/

# Make port 8025 available to the world outside this container
EXPOSE 8025
CMD ["main.py", "/etc"]