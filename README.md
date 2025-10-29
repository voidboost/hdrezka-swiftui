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
<p>
    <img width="49%" src="https://github.com/user-attachments/assets/717fce79-2084-4fed-ac8c-64ae601cd581" />
    <img width="49%" src="https://github.com/user-attachments/assets/cd186b48-db12-430a-8ed7-241f3125f16b" />
</p>
<p>
    <img width="49%" src="https://github.com/user-attachments/assets/287c84fb-d9e2-4def-8799-0d853d81c866" />
    <img width="49%" src="https://github.com/user-attachments/assets/b8d6794c-95c7-41ff-adc6-d2ce2810dd71" />
</p>
<p>
    <img width="49%" src="https://github.com/user-attachments/assets/5c81b065-c7cd-4f3c-b4bd-8aeade5fb9ed" />
    <img width="49%" src="https://github.com/user-attachments/assets/233e6cf2-8309-42af-b2f5-7f1af84d7d11" />
</p>
<p>
    <img width="49%" src="https://github.com/user-attachments/assets/1d414ad3-9a24-4f40-ba74-d5648c75640b" />
    <img width="49%" src="https://github.com/user-attachments/assets/53c79acb-e224-4209-bc6f-e4872b44516c" />
</p>
<p>
    <img width="49%" src="https://github.com/user-attachments/assets/8a6eb493-8f44-4e9c-b81a-16736b4e6a58" />
    <img width="49%" src="https://github.com/user-attachments/assets/68a189a0-bb3b-4fe0-812f-2dd81dee9664" />
</p>
<p>
    <img width="49%" src="https://github.com/user-attachments/assets/6ac5bd9c-7818-46ec-a0ef-cd0cd2403aef" />
    <img width="49%" src="https://github.com/user-attachments/assets/d5dad8ff-5131-4d28-820c-109d6a8d7c13" />
</p>
<p>
    <img width="49%" src="https://github.com/user-attachments/assets/987b4b94-5c96-4db4-86e4-41138ae5e65f" />
    <img width="49%" src="https://github.com/user-attachments/assets/cda7d6f4-11aa-45b1-84d0-006611f319eb" />
</p>
<p>
    <img width="49%" src="https://github.com/user-attachments/assets/516e4c93-06fc-4f1a-ad3e-d72c24057673" />
    <img width="49%" src="https://github.com/user-attachments/assets/35a7cee0-0de7-4d5c-91e2-f4e4c4d00fb9" />
</p>
<p>
    <img width="49%" src="https://github.com/user-attachments/assets/411b8655-c237-43c0-ae2c-3ee5ebf8cfb0" />
    <img width="49%" src="https://github.com/user-attachments/assets/5d64a920-96c4-469f-ac65-9ae68f8aa821" />
</p>
<p>
    <img width="49%" src="https://github.com/user-attachments/assets/56004c24-4dd1-49ae-bd3b-7700e0dc5534" />
    <img width="49%" src="https://github.com/user-attachments/assets/ca1d185e-d90f-4607-8c5b-28c583bce7a8" />
</p>
<p>
    <img width="49%" src="https://github.com/user-attachments/assets/9e4f98ae-e44b-4fe8-9218-87dad0a52c81" />
    <img width="49%" src="https://github.com/user-attachments/assets/45590091-f8e8-4bd6-9682-e24cc9b898c4" />
</p>
<p>
    <img width="49%" src="https://github.com/user-attachments/assets/5df3dd8e-24c9-4ff4-9a37-39b4cfb1fa5a" />
</p>
<h2>📄 Лицензия</h2>
<p>
    <a href="./LICENSE" target="_blank">MIT License</a>
</p>
