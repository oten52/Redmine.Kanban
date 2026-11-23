# Redmine Kanban

Her projeye Kanban sekmesi ekler. Sütunlar iş durumları, kartlar işlerdir.

[English](README.md)

## Yenilikler

* 0.3.1: Durum penceresinde atanan aranır ve nota dosya eklenir. Ayrıntılar [CHANGELOG](CHANGELOG.md) dosyasında.

## Ne yapar

* İşleri görebilen kullanıcılar için proje menüsünde, İşler sekmesinin yanında Kanban sekmesi açılır.
* Kayıtlı iş sorgularından bir veya birkaçını seçersiniz. Liste o sorguların güncel sonucudur.
* Gösterilecek durumlar ayrıca seçilir. Seçilmezse açık durumlar gelir.
* Görünüm kısayol olarak kaydedilir. Sorgularla aynı şekilde düzenlenir, silinir ve görünürlüğü değiştirilir: yalnızca bana, herkese veya seçilen rollere. Tüm projelerde de kullanılabilir.
* Kısayollar sağ menüde durur. Kaydetme izni, sorgu kaydetme izniyle aynıdır. Herkese veya rollere açmak, genel sorgu yönetme iznini ister.
* Kartı başka sütuna sürükleyince durum değişir. İş akışı ve düzenleme izni kontrol edilir.
* "Durum değişirken sor" açıksa atanan, not, dosya, tarihler ve tamamlanma oranı sorulur. Kapalıyken durum doğrudan değişir.
* Eşleşen işlerden en son güncellenen 400 tanesi gösterilir.

## Redmine sürümü

* 4.2.x ~ 6.x

Ek gem ve asset derlemesi gerekmez. Kısayollar için bir veritabanı göçü vardır.

## Kurulum

1. Redmine `plugins` dizininde:

```bash
git clone https://github.com/oten52/Redmine.Kanban.git
```

Klasör adı `Redmine.Kanban` olarak kalabilir.

2. Eklenti göçünü çalıştırın ve Redmine'ı yeniden başlatın.

```bash
docker exec redmine-redmine-1 bundle exec rake redmine:plugins:migrate NAME=redmine_kanban RAILS_ENV=production
docker restart redmine-redmine-1
```

Bir projeyi açın. Kanban sekmesi İşler sekmesinin yanındadır. Sorgu ve durum seçip Kısa yola ekle deyin.

## Güncelleme

0.3.1 yeni bir göç eklemez. 0.2.0 göçü yapıldıysa çekip yeniden başlatmak yeter. Aşağıdaki göç komutu tekrar çalıştırılabilir.

```bash
cd /home/niltek/redmine/app/plugins/Redmine.Kanban
sudo -u niltek git pull
docker exec redmine-redmine-1 bundle exec rake redmine:plugins:migrate NAME=redmine_kanban RAILS_ENV=production
docker restart redmine-redmine-1
```

## Kaldırma

1. `Redmine.Kanban` klasörünü silin.
2. Redmine'ı yeniden başlatın.

## Yazar

Niltek Arge — https://github.com/oten52

## Lisans

GNU General Public License v3.0 veya sonrası. Ayrıntı için [LICENSE](LICENSE).

Bu eklentiyi değiştirip dağıtırsanız telif bildirimlerini koruyun, değişikliklerinizi belirtin ve
sürümünüzü aynı lisansla dağıtın.
