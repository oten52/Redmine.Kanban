# Redmine Kanban

Her projeye Kanban sekmesi ekler. Sütunlar iş durumları, kartlar işlerdir.

[English](README.md)

## Yenilikler

* 0.1.0: İlk sürüm. Ayrıntılar [CHANGELOG](CHANGELOG.md) dosyasında.

## Ne yapar

* İşleri görebilen kullanıcılar için proje menüsünde, İşler sekmesinin yanında Kanban sekmesi açılır.
* Sütunlar projedeki iş tiplerinin iş akışından gelir. Kapalı durumlar süzgeçle gösterilebilir.
* Kartı başka sütuna sürükleyince durum değişir. Kartın içinden de durum seçilebilir. İş akışı ve düzenleme izni kontrol edilir.
* İş tipi, atanan, öncelik, sürüm ve konuya göre süzülür.
* Eşleşen işlerden en son güncellenen 400 tanesi gösterilir.

## Redmine sürümü

* 4.2.x ~ 6.x

Veritabanı göçü, ek gem ve asset derlemesi gerekmez.

## Kurulum

1. Redmine `plugins` dizininde:

```bash
git clone https://github.com/oten52/Redmine.Kanban.git
```

Klasör adı `Redmine.Kanban` olarak kalabilir.

2. Redmine'ı yeniden başlatın.

Bir projeyi açın. Kanban sekmesi İşler sekmesinin yanındadır.

## Kaldırma

1. `Redmine.Kanban` klasörünü silin.
2. Redmine'ı yeniden başlatın.

## Yazar

Niltek Arge — https://github.com/oten52

## Lisans

GNU General Public License v3.0 veya sonrası. Ayrıntı için [LICENSE](LICENSE).

Bu eklentiyi değiştirip dağıtırsanız telif bildirimlerini koruyun, değişikliklerinizi belirtin ve
sürümünüzü aynı lisansla dağıtın.
