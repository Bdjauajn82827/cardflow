# Настройка проекта в Vercel

## Шаг 1: Войдите в Vercel и создайте новый проект

1. Перейдите на [Vercel](https://vercel.com/) и войдите в свою учетную запись
2. Нажмите кнопку "Add New" > "Project"
3. Выберите свой GitHub репозиторий "cardflow"
4. Вы будете перенаправлены на страницу настройки проекта

## Шаг 2: Настройка параметров проекта

На странице настройки проекта укажите следующие параметры:

- **Framework Preset**: выберите "Other"
- **Root Directory**: оставьте пустым (используйте корневую директорию)
- **Build Command**: `npm run build`
- **Output Directory**: `frontend/build`
- **Install Command**: `npm run install-all`

## Шаг 3: Настройка переменных окружения

Перед нажатием кнопки "Deploy", перейдите к разделу "Environment Variables" и добавьте следующие переменные:

| Название переменной | Значение |
|--------------------|----------|
| `NODE_ENV` | `production` |
| `PORT` | `5000` |
| `DATABASE_URL` | `postgresql://postgres:IFEzoP0ppdwJ7d39@db.eskiyhqhittzpwoxfmvq.supabase.co:5432/postgres` |
| `DB_NAME` | `postgres` |
| `DB_USER` | `postgres` |
| `DB_PASSWORD` | `IFEzoP0ppdwJ7d39` |
| `DB_HOST` | `db.eskiyhqhittzpwoxfmvq.supabase.co` |
| `DB_PORT` | `5432` |
| `JWT_SECRET` | `059713690b6fa1eba46f5c97d4307a6f9c0077c34329dd8bacd931513b67496a1d2ac56c72ff0e88b7cb77cc3928c9eee2c90dd5e5889bd7cdaf14dbca57bcde` |
| `JWT_EXPIRES_IN` | `7d` |

Для JWT_SECRET рекомендуется использовать длинную случайную строку. Вы можете сгенерировать её с помощью:
```
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## Шаг 4: Деплой проекта

После настройки всех переменных окружения нажмите кнопку "Deploy"

## Шаг 5: Настройка домена

После успешного деплоя:
1. Перейдите в раздел "Domains" в настройках проекта
2. Нажмите "Add" для добавления вашего кастомного домена
3. Следуйте инструкциям Vercel по настройке DNS-записей

## Важные замечания

- Убедитесь, что вы выполнили SQL-скрипт из файла `database_schema.sql` в SQL Editor Supabase
- Если вы вносите изменения в переменные окружения после деплоя, может потребоваться перезапуск проекта через кнопку "Redeploy"
- Для мониторинга логов и отладки используйте вкладку "Logs" в интерфейсе Vercel
