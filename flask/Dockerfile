FROM python:2.7
WORKDIR /app
ENV ENVIRONMENT "development"
EXPOSE 5000
COPY requirements.txt /app/
RUN pip install -r requirements.txt
COPY runserver.py db.py /app/
COPY notejam notejam
CMD python runserver.py