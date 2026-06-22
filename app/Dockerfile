# Hangi Python versiyonunu kullanacağız?
FROM python:3.11-slim

# Container içinde çalışma klasörü
WORKDIR /app

# Önce bağımlılıkları kopyala ve kur
# (Bu sıra önemli — Docker cache optimizasyonu)
COPY requirements.txt .
RUN pip install -r requirements.txt

# Sonra uygulama kodunu kopyala
COPY . .

# Bu container 5000 portunu kullanacak
EXPOSE 5000

# Container başlayınca çalışacak komut
CMD ["python", "main.py"]