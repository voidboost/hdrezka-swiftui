<h2>🌐 Мова / Language</h2>
<ul>
    <li>
        <a href="./README_UA.md" target="_blank">Українська 🇺🇦</a>
    </li>
    <li>
        <a href="./README_EN.md" target="_blank">English 🇺🇸</a>
    </li>
</ul>
<h1>🎬 HDrezka для macOS (неофициальный клиент)</h1>
<p>Неофициальное клиент HDrezka для macOS. <br>Требуется <b>macOS 15 Sequoia</b> или новее.</p>
<h2>⚠️ Отказ от ответственности</h2>
<ul>
   <li>Эта программа предоставляется <b>«как есть»</b>.</li>
   <li>Автор <b>не поощряет какую-либо незаконную деятельность</b>.</li>
   <li>Используйте её исключительно <b>на свой страх и риск</b>.</li>
   <li>Также рекомендуется ознакомиться с <a href="https://rezka.ag/rules/"><b>правилами сайта</b></a>.</li>
</ul>
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
<h2>📦 Установка с помощью <a href="https://brew.sh/">Homebrew</a></h2>
<p><strong>Homebrew 5.x и более ранние версии</strong></p>
<pre><code>brew tap voidboost/hdrezka && brew install --cask hdrezka</code></pre>
<p><strong>Homebrew 6.x и более новые версии</strong></p>
<pre><code>brew tap voidboost/hdrezka && brew trust voidboost/hdrezka && brew install --cask hdrezka</code></pre>
<p><em>В Homebrew 6.x необходимо явно доверять сторонним tap-репозиторям перед установкой пакетов из них.</em></p>
<h2>🚀 Релизы</h2>
<ul>
    <li>
        <span> 💻 </span>
        <a href="https://voidboost.github.io/hdrezka-releases/HDrezka.dmg" target="_blank">Скачать последнюю версию (macOS 15 Sequoia или новее)</a>
    </li>
</ul>
<h2>💖 Поддержка проекта</h2>
<p>Чтобы приложение оставалось актуальным, вы можете поддержать его спонсорством на GitHub. <br>Если вам нужна помощь с установкой или настройкой, свяжитесь со мной в Telegram: <a href="https://t.me/voidboost" target="_blank">@voidboost</a>.</p>
<h2>🧰 Решение проблем</h2>
<h3>Ошибка при установке или запуске на macOS</h3>
<p>Если приложение не запускается, выполните эти команды в Терминале:</p>
<pre><code>sudo xattr -dr com.apple.quarantine /Applications/HDrezka.app</code></pre>
<p>Затем:</p>
<pre><code>sudo codesign --force --deep --sign - /Applications/HDrezka.app</code></pre>
<h2>🖼 Скриншоты</h2>
<table>
    <thead>
        <tr>
            <th>macOS</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/4b590d4d-5e88-45b7-8433-65d8d286e719" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/14956a97-951a-426c-bc42-e6d652be9854" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/cffd257e-66f1-4900-9a33-7be8941ad73d" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/611d3919-128a-464f-b5c9-2a8bd936154f" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/d83eefb0-7c3f-4149-af73-e33bf9303898" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/2f49ece6-ca7e-4c46-827a-e151a1902a5b" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/92da7e12-594f-4f29-aa6c-db27dd7883fc" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/93c60bef-6e2e-4592-91a2-1e190816f2c5" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/729de52f-0d3c-4da9-bbdc-ec28c2a16952" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/49d875c4-1e73-4a11-9c41-042ad776da6b" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/8b4cee8c-0fb5-41cb-9a45-1c416fe2e7cf" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/f97b4905-8b13-4139-b36b-c5334db3eeb9" /></td>
        </tr>
    </tbody>
</table>
<h2>📄 Лицензия</h2>
<p>
    <a href="./LICENSE" target="_blank">MIT License</a>
</p>
