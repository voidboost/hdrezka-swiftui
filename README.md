<h2>🌐 Мова / Language</h2>
<ul>
    <li>
        <a href="./README_UA.md" target="_blank">Українська 🇺🇦</a>
    </li>
    <li>
        <a href="./README_EN.md" target="_blank">English 🇺🇸</a>
    </li>
</ul>
<h1>🎬 HDrezka для macOS / iPadOS (неофициальный клиент)</h1>
<p>Неофициальное клиент HDrezka для macOS и iPadOS. <br>Требуется <b>macOS 15 Sequoia / iPadOS 18</b> или новее.</p>
<h2>✨ Возможности</h2>
<ul>
    <li>🎞 Кастомный видеоплеер</li>
    <li>🔐 Авторизация аккаунта</li>
    <li>📌 Закладки для любимого контента</li>
    <li>💬 Комментарии и обсуждения</li>
    <li>🎥 Удобный список фильмов и сериалов</li>
    <li>🌗 Поддержка светлой и тёмной темы</li>
    <li>🌍 Локализация: английский, украинский, русский</li>
    <li>🔎 Поиск</li>
    <li>⬇️ Возможность загрузки видео</li>
</ul>
<p>
    <i>И многое другое!</i>
</p>
<h2>🚀 Релизы</h2>
<ul>
    <li>
        <span> 💻 </span>
        <a href="https://voidboost.github.io/hdrezka-releases/HDrezka 1.0.23.dmg" target="_blank">Скачать последнюю версию (macOS 15 Sequoia или новее)</a>
    </li>
    <li>
        <span> 📱 </span>
        <a href="https://voidboost.github.io/hdrezka-releases/HDrezka 1.0.23.ipa" target="_blank">Скачать последнюю версию (iPadOS 18 или новее)</a>
        <sup>бета</sup>
    </li>
</ul>
<h2>💖 Поддержка проекта</h2>
<p>Чтобы приложение оставалось актуальным, вы можете поддержать его спонсорством на GitHub. <br>Если вам нужна помощь с установкой или настройкой, свяжитесь со мной в Telegram: <a href="https://t.me/voidboost" target="_blank">@voidboost</a>.</p>
<h2>🧰 Решение проблем</h2>
<h3>Ошибка при установке или запуске на macOS</h3>
<p>Если приложение не запускается, выполните эти команды в Терминале:</p>
<pre><code>sudo xattr -cr /Applications/HDrezka.app</code></pre>
<p>Затем:</p>
<pre><code>sudo codesign --force --deep --sign - /Applications/HDrezka.app</code></pre>
<h3>Установка на iPadOS</h3>
<h4>1️⃣ Через Sideloadly (с компьютером)</h4>
<p>
    <b>Sideloadly</b> — инструмент для установки IPA-файлов с компьютера (Windows / macOS). Приложение работает 7 дней, затем требует повторной подписи.
</p>
<details>
    <summary>📘 Полный гайд по установке через Sideloadly</summary>
    <h5>Требуется:</h5>
    <ol>
        <li>Компьютер с Windows или macOS</li>
        <li><a href="https://sideloadly.io/" target="_blank">Sideloadly</a></li>
        <li>iTunes и iCloud (для Windows — с сайта Apple)</li>
        <li>Отдельный Apple ID (рекомендуется)</li>
        <li>IPA-файл HDrezka (см. выше)</li>
        <li>USB-кабель</li>
    </ol>
    <h5>Пошагово:</h5>
    <ol>
        <li>Установите Sideloadly и запустите программу.</li>
        <li>Подключите iPad через USB, выберите "Доверять этому компьютеру".</li>
        <li>Введите Apple ID и загрузите IPA-файл HDrezka.</li>
        <li>Нажмите <b>Start</b> и дождитесь установки.</li>
        <li>После установки перейдите в <b>Настройки → Основные → Профили</b> и нажмите <b>Доверять</b>.</li>
    </ol>
</details>
<h4>2️⃣ Через AltStore (с компьютером)</h4>
<p>
    <b>AltStore</b> позволяет подписывать IPA-файлы прямо на устройстве. Требуется повторная подпись каждые 7 дней, но это можно делать автоматически.
</p>
<details>
    <summary>📘 Полный гайд по установке через AltStore</summary>
    <h5>Требуется:</h5>
    <ol>
        <li>Компьютер с Windows или macOS</li>
        <li><a href="https://altstore.io/" target="_blank">AltStore</a></li>
        <li>iTunes и iCloud</li>
        <li>Отдельный Apple ID</li>
        <li>IPA-файл HDrezka (см. выше)</li>
    </ol>
    <h5>Пошагово:</h5>
    <ol>
        <li>Установите AltStore на компьютер.</li>
        <li>Подключите iPad и установите AltStore на устройство.</li>
        <li>Подпишите профиль в <b>Настройки → Основные → Профили</b>.</li>
        <li>В AltStore выберите IPA-файл HDrezka для установки.</li>
        <li>После установки приложение появится на главном экране.</li>
    </ol>
</details>
<h4>3️⃣ Через GBox (без компьютера, с сертификатом)</h4>
<p>Способ без компьютера. Требуется платный сертификат разработчика, который можно приобрести через <a href="https://t.me/glesign" target="_blank">GLESign</a>.</p>
<details>
    <summary>📘 Полный гайд по установке через GBox</summary>
    <h5>Требуется:</h5>
    <ol>
        <li>iPad</li>
        <li>Приложение <b>GBox</b></li>
        <li>Платный сертификат (<a href="https://t.me/glesign" target="_blank">GLESign</a>)</li>
        <li>IPA-файл HDrezka (см. выше)</li>
    </ol>
    <h5>Пошагово:</h5>
    <ol>
        <li>Приобретите сертификат и установите GBox по выданной ссылке.</li>
        <li>Добавьте сертификат в GBox (помощь в <a href="http://t.me/glesign_support" target="_blank">GLESign Support</a>).</li>
        <li>Откройте IPA-файл HDrezka и поделитесь им с GBox.</li>
        <li>Подпишите и установите приложение через GBox.</li>
        <li>После завершения установки HDrezka появится на домашнем экране.</li>
    </ol>
</details>
<h2>🖼 Скриншоты</h2>
<table>
    <thead>
        <tr>
            <th>macOS</th>
            <th>iPadOS</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/4b590d4d-5e88-45b7-8433-65d8d286e719" /></td>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/1957c128-8d42-41a2-a086-4d4e3426a9f6" /></td>
        </tr>
        <tr>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/14956a97-951a-426c-bc42-e6d652be9854" /></td>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/02372027-eae7-4d94-a206-405f9b8f4c13" /></td>
        </tr>
        <tr>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/cffd257e-66f1-4900-9a33-7be8941ad73d" /></td>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/9e3997ae-206b-4ae4-a352-876863f7eb7a" /></td>
        </tr>
        <tr>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/611d3919-128a-464f-b5c9-2a8bd936154f" /></td>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/b3b18101-635c-4d52-939e-25997a560b81" /></td>
        </tr>
        <tr>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/d83eefb0-7c3f-4149-af73-e33bf9303898" /></td>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/c74d5377-506c-42a6-8826-31d5d733fae4" /></td>
        </tr>
        <tr>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/2f49ece6-ca7e-4c46-827a-e151a1902a5b" /></td>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/77b831d0-7f42-41fe-9d5b-fda2f377d44e" /></td>
        </tr>
        <tr>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/92da7e12-594f-4f29-aa6c-db27dd7883fc" /></td>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/13badb71-2005-464e-9f01-47f97a4246b5" /></td>
        </tr>
        <tr>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/93c60bef-6e2e-4592-91a2-1e190816f2c5" /></td>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/5196ea56-7c8d-4b4b-9286-531e7c81c604" /></td>
        </tr>
        <tr>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/729de52f-0d3c-4da9-bbdc-ec28c2a16952" /></td>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/a6f128a9-a152-4ec8-85bd-a72f0c737313" /></td>
        </tr>
        <tr>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/49d875c4-1e73-4a11-9c41-042ad776da6b" /></td>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/5b264707-9fce-491a-9f7b-07359c0e0b49" /></td>
        </tr>
        <tr>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/8b4cee8c-0fb5-41cb-9a45-1c416fe2e7cf" /></td>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/4aada4a1-eba4-49a8-975b-56cd46d5c339" /></td>
        </tr>
        <tr>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/f97b4905-8b13-4139-b36b-c5334db3eeb9" /></td>
            <td><img width="100%" loading="lazy" src="https://github.com/user-attachments/assets/c33353f2-9d69-48d1-86b1-87b6142b8bd9" /></td>
        </tr>
    </tbody>
</table>
<h2>📄 Лицензия</h2>
<p>
    <a href="./LICENSE" target="_blank">MIT License</a>
</p>
