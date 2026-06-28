# DevOps Tutorial — Uçtan Uca CI/CD Pipeline

Bir Python (Flask) uygulamasının; **Docker** ile paketlenip, **Terraform** ile sağlanan AWS altyapısına, **Jenkins** CI/CD pipeline'ı aracılığıyla **Kubernetes (k3s)** üzerine otomatik olarak deploy edildiği uçtan uca bir DevOps projesi. Sunucu yapılandırması **Ansible** ile, kod değişiklikleri ise **GitHub webhook** ile tetiklenen tam otomatik bir akışla yönetilir.

---

## İçindekiler

- [Mimari](#mimari)
- [Kullanılan Teknolojiler](#kullanılan-teknolojiler)
- [Proje Yapısı](#proje-yapısı)
- [CI/CD Akışı](#cicd-akışı)
- [Kurulum](#kurulum)
- [Kullanım](#kullanım)
- [Öğrenilen Kavramlar](#öğrenilen-kavramlar)

---

## Mimari

Proje, sorumlulukları ayrılmış üç ayrı AWS EC2 sunucusu üzerine kuruludur:

```
                          ┌─────────────────┐
                          │     GitHub      │
                          │   (kod deposu)  │
                          └────────┬────────┘
                                   │ webhook (her push'ta)
                                   ▼
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Jenkins Sunucu  │     │   k3s Sunucu     │     │  Uygulama Sunucu │
│   (t3.small)     │────▶│   (t3.small)     │     │   (t3.micro)     │
│                  │     │                  │     │                  │
│ • CI/CD pipeline │     │ • Kubernetes     │     │ • Docker         │
│ • Ansible        │     │ • 2 pod replica  │     │ • (ilk deploy)   │
│ • Docker build   │     │ • Rolling update │     │                  │
└────────┬─────────┘     └──────────────────┘     └──────────────────┘
         │                        ▲
         │  docker push           │ kubectl set image
         ▼                        │
   ┌──────────────┐               │
   │  Docker Hub  │───────────────┘
   │  (registry)  │   image pull
   └──────────────┘
```

**Akış:** Geliştirici kodu GitHub'a push eder → GitHub webhook ile Jenkins'i tetikler → Jenkins kodu test eder, Docker image'ı build eder, Docker Hub'a gönderir → k3s sunucusundaki Kubernetes deployment'ını yeni image ile kesintisiz (rolling update) günceller.

---

## Kullanılan Teknolojiler

| Kategori | Teknoloji | Görevi |
|----------|-----------|--------|
| **Uygulama** | Python 3.11 + Flask | Web uygulaması (REST API) |
| **Konteynerleştirme** | Docker | Uygulamayı taşınabilir image olarak paketleme |
| **Image Kayıt Defteri** | Docker Hub | Image'ların saklandığı registry |
| **Altyapı (IaC)** | Terraform | AWS sunucularını kod ile sağlama (provisioning) |
| **Yapılandırma Yönetimi** | Ansible | Sunucu kurulumunu (Docker vb.) otomatikleştirme |
| **CI/CD** | Jenkins | Test, build ve deploy otomasyonu |
| **Orkestrasyon** | Kubernetes (k3s) | Konteyner yönetimi, replica, self-healing |
| **Bulut** | AWS EC2 | Sunucu altyapısı |
| **Versiyon Kontrolü** | Git + GitHub | Kod yönetimi ve webhook tetikleme |

---

## Proje Yapısı

```
devops-tutorial/
├── app/                          # Flask uygulaması
│   ├── main.py                   # Uygulama kodu (/ ve /health uç noktaları)
│   ├── requirements.txt          # Python bağımlılıkları (flask, pytest)
│   ├── test_main.py              # Otomatik testler (pytest)
│   └── Dockerfile                # Image tarifi
│
├── terraform-aws/                # Altyapı kodu (IaC)
│   ├── main.tf                   # Uygulama sunucusu + SSH key + güvenlik grubu
│   ├── jenkins.tf                # Jenkins sunucusu + güvenlik grubu
│   └── k3s.tf                    # k3s sunucusu + güvenlik grubu
│
├── ansible/                      # Yapılandırma yönetimi
│   ├── inventory.ini             # Hedef sunucu envanteri
│   └── docker-setup.yml          # Docker kurulum playbook'u
│
├── k8s/                          # Kubernetes manifestleri
│   └── app-deployment.yaml       # Deployment (2 replica) + Service (NodePort)
│
├── Jenkinsfile                   # CI/CD pipeline tanımı
├── .gitignore                    # tfstate, secrets, vb. hariç tutulanlar
└── README.md
```

> **Not:** `terraform.tfstate` ve `.terraform/` gibi hassas/büyük dosyalar `.gitignore` ile versiyon kontrolünün dışında tutulmuştur.

---

## CI/CD Akışı

Jenkins pipeline'ı beş aşamadan oluşur:

| Aşama | İşlem |
|-------|-------|
| **1. Checkout** | GitHub'dan en güncel kodu çeker |
| **2. Build** | Docker image'ı build eder (`:BUILD_NUMBER` ve `:latest` etiketleriyle) |
| **3. Test** | Image içinde `pytest` çalıştırır — başarısızsa pipeline durur |
| **4. Push** | Image'ı Docker Hub'a gönderir (token ile güvenli kimlik doğrulama) |
| **5. Deploy** | k3s'te `kubectl set image` ile rolling update yapar |

**Güvenlik kapısı:** Test aşaması başarısız olursa, sonraki aşamalar (Push, Deploy) hiç çalışmaz. Bu sayede bozuk kod asla canlıya çıkmaz.

**Versiyonlama:** Her image, Jenkins build numarasıyla etiketlenir; bu, hangi sürümün deploy edildiğinin izlenmesini ve gerektiğinde eski sürüme dönülmesini sağlar.

**Sıfır kesinti:** Kubernetes rolling update, pod'ları teker teker yenileyerek güncelleme boyunca uygulamanın erişilebilir kalmasını sağlar.

---

## Kurulum

### Ön Koşullar

- AWS hesabı ve yapılandırılmış AWS CLI (`aws configure`)
- Terraform (>= 1.0)
- Bir SSH anahtar çifti (`ssh-keygen`)
- Docker Hub hesabı

### 1. Altyapıyı Sağla (Terraform)

```bash
cd terraform-aws
terraform init
terraform plan
terraform apply
```

Bu komut üç sunucuyu (uygulama, Jenkins, k3s) ve gerekli güvenlik gruplarını oluşturur. Çıktıda her sunucunun public IP'si görünür.

### 2. Sunucuları Yapılandır (Ansible)

```bash
cd ansible
ansible-playbook -i inventory.ini docker-setup.yml
```

### 3. k3s Kurulumu

k3s sunucusunda:

```bash
curl -sfL https://get.k3s.io | sh -
kubectl apply -f k8s/app-deployment.yaml
```

### 4. Jenkins Kurulumu

Jenkins sunucusunda Docker ile çalıştırılır; `SSH Agent` eklentisi kurulur, gerekli credential'lar (`aws-ssh-key`, `dockerhub-cred`) eklenir ve pipeline `Jenkinsfile`'dan oluşturulur. GitHub webhook ile otomatik tetikleme bağlanır.

---

## Kullanım

Sistem kurulduktan sonra, yeni bir sürüm yayınlamak için tek yapılması gereken kodu değiştirip push etmektir:

```bash
# 1. Kodu değiştir (örn. app/main.py)
# 2. Testi güncelle (gerekiyorsa)
git add .
git commit -m "feat: yeni özellik"
git push
```

Geri kalan her şey otomatik gerçekleşir: webhook Jenkins'i tetikler → test → build → Docker Hub'a push → Kubernetes rolling update. Birkaç dakika içinde yeni sürüm canlıda olur.

**Uygulamaya erişim:** `http://<k3s-sunucu-ip>:30080`

**Uç noktalar:**
- `GET /` — Karşılama mesajı ve sürüm bilgisi
- `GET /health` — Sağlık kontrolü (`{"status": "ok"}`)

---

## Öğrenilen Kavramlar

Bu proje boyunca uygulanan temel DevOps prensipleri:

- **Infrastructure as Code (IaC):** Altyapının fareyle değil, Terraform ile kod üzerinden yönetilmesi — tekrarlanabilir ve versiyonlanabilir.
- **Konteynerleştirme:** Uygulamanın bağımlılıklarıyla birlikte taşınabilir Docker image olarak paketlenmesi.
- **CI/CD:** Test, build ve deploy süreçlerinin otomatikleştirilmesi; bozuk kodun test kapısıyla engellenmesi.
- **Konteyner Orkestrasyonu:** Kubernetes ile çoklu replica yönetimi, self-healing (kendini iyileştirme) ve sıfır kesintili güncellemeler.
- **Yapılandırma Yönetimi:** Ansible ile sunucu kurulumlarının idempotent (tekrarlanabilir, yan etkisiz) şekilde otomatikleştirilmesi.
- **Güvenli Kimlik Yönetimi:** Gizli anahtar ve token'ların koda gömülmeden, credential store ve `.gitignore` ile yönetilmesi.

---

## Lisans

Bu proje öğrenme amaçlı hazırlanmıştır.
