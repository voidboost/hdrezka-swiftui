<h1>🎬 HDrezka для macOS / iPadOS (неофіційний клієнт)</h1>
<p>Неофіційний клієнт HDrezka для macOS та iPadOS. <br>Потрібна <b>macOS 15 Sequoia / iPadOS 18</b> або новіша.</p>
<h2>✨ Можливості</h2>
<ul>
    <li>🎞 Кастомний відеоплеєр</li>
    <li>🔐 Авторизація акаунта</li>
    <li>📌 Закладки для улюбленого контенту</li>
    <li>💬 Коментарі та обговорення</li>
    <li>🎥 Зручний список фільмів і серіалів</li>
    <li>🌗 Підтримка світлої та темної теми</li>
    <li>🌍 Локалізація: англійська, українська, російська</li>
    <li>🔎 Пошук</li>
    <li>⬇️ Можливість завантаження відео</li>
</ul>
<p><i>І багато іншого!</i></p>
<h2>🚀 Релізи</h2>
<ul>
    <li>
        <span> 💻 </span>
        <a href="https://voidboost.github.io/hdrezka-releases/HDrezka 1.0.27.dmg" target="_blank">Завантажити останню версію (macOS 15 Sequoia або новіша)</a>
    </li>
    <li>
        <span> 📱 </span>
        <a href="https://voidboost.github.io/hdrezka-releases/HDrezka 1.0.27.ipa" target="_blank">Завантажити останню версію (iPadOS 18 або новіша)</a>
        <sup>бета</sup>
    </li>
</ul>
<h2>💖 Підтримка проєкту</h2>
<p>Щоб застосунок залишався актуальним, ви можете підтримати його спонсорством на GitHub. <br>Якщо вам потрібна допомога з інсталяцією або налаштуванням — зв’яжіться зі мною в Telegram: <a href="https://t.me/voidboost" target="_blank">@voidboost</a>.</p>
<h2>🧰 Вирішення проблем</h2>
<h3>Помилка під час встановлення або запуску на macOS</h3>
<p>Якщо застосунок не запускається, виконайте ці команди в Терміналі:</p>
<pre><code>sudo xattr -cr /Applications/HDrezka.app</code></pre>
<p>Потім:</p>
<pre><code>sudo codesign --force --deep --sign - /Applications/HDrezka.app</code></pre>
<h3>Встановлення на iPadOS</h3>
<h4>1️⃣ Через Sideloadly (з комп’ютером)</h4>
<p><b>Sideloadly</b> — інструмент для встановлення IPA-файлів із комп’ютера (Windows / macOS). Додаток працює 7 днів, після чого потребує повторного підпису.</p>
<details>
    <summary>📘 Повна інструкція зі встановлення через Sideloadly</summary>
    <h5>Потрібно:</h5>
    <ol>
        <li>Комп’ютер з Windows або macOS</li>
        <li><a href="https://sideloadly.io/" target="_blank">Sideloadly</a></li>
        <li>iTunes і iCloud (для Windows — із сайту Apple)</li>
        <li>Окремий Apple ID (рекомендовано)</li>
        <li>IPA-файл HDrezka (див. вище)</li>
        <li>USB-кабель</li>
    </ol>
    <h5>Покроково:</h5>
    <ol>
        <li>Встановіть Sideloadly та запустіть програму.</li>
        <li>Підключіть iPad через USB, виберіть «Довіряти цьому комп’ютеру».</li>
        <li>Введіть Apple ID і завантажте IPA-файл HDrezka.</li>
        <li>Натисніть <b>Start</b> і дочекайтеся завершення встановлення.</li>
        <li>Після інсталяції перейдіть у <b>Налаштування → Основні → Профілі</b> і натисніть <b>Довіряти</b>.</li>
    </ol>
</details>
<h4>2️⃣ Через AltStore (з комп’ютером)</h4>
<p><b>AltStore</b> дозволяє підписувати IPA-файли безпосередньо на пристрої. Потрібне оновлення підпису кожні 7 днів, але це можна автоматизувати.</p>
<details>
    <summary>📘 Повна інструкція зі встановлення через AltStore</summary>
    <h5>Потрібно:</h5>
    <ol>
        <li>Комп’ютер з Windows або macOS</li>
        <li><a href="https://altstore.io/" target="_blank">AltStore</a></li>
        <li>iTunes і iCloud</li>
        <li>Окремий Apple ID</li>
        <li>IPA-файл HDrezka (див. вище)</li>
    </ol>
    <h5>Покроково:</h5>
    <ol>
        <li>Встановіть AltStore на комп’ютер.</li>
        <li>Підключіть iPad і встановіть AltStore на пристрій.</li>
        <li>Підпишіть профіль у <b>Налаштування → Основні → Профілі</b>.</li>
        <li>В AltStore виберіть IPA-файл HDrezka для встановлення.</li>
        <li>Після інсталяції застосунок з’явиться на головному екрані.</li>
    </ol>
</details>
<h4>3️⃣ Через GBox (без комп’ютера, із сертифікатом)</h4>
<p>Метод без комп’ютера. Потрібен платний сертифікат розробника, який можна придбати через <a href="https://t.me/glesign" target="_blank">GLESign</a>.</p>
<details>
    <summary>📘 Повна інструкція зі встановлення через GBox</summary>
    <h5>Потрібно:</h5>
    <ol>
        <li>iPad</li>
        <li>Додаток <b>GBox</b></li>
        <li>Платний сертифікат (<a href="https://t.me/glesign" target="_blank">GLESign</a>)</li>
        <li>IPA-файл HDrezka (див. вище)</li>
    </ol>
    <h5>Покроково:</h5>
    <ol>
        <li>Придбайте сертифікат і встановіть GBox за наданим посиланням.</li>
        <li>Додайте сертифікат у GBox (допомога — <a href="http://t.me/glesign_support" target="_blank">GLESign Support</a>).</li>
        <li>Відкрийте IPA-файл HDrezka і поділіться ним із GBox.</li>
        <li>Підпишіть і встановіть застосунок через GBox.</li>
        <li>Після завершення інсталяції HDrezka з’явиться на головному екрані.</li>
    </ol>
</details>
<h2>🖼 Скриншоти</h2>
<table>
    <thead>
        <tr>
            <th>macOS</th>
            <th>iPadOS</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/4b590d4d-5e88-45b7-8433-65d8d286e719" /></td>
            <td><img width="100%" src="https://github.com/user-attachments/assets/1957c128-8d42-41a2-a086-4d4e3426a9f6" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/14956a97-951a-426c-bc42-e6d652be9854" /></td>
            <td><img width="100%" src="https://github.com/user-attachments/assets/02372027-eae7-4d94-a206-405f9b8f4c13" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/cffd257e-66f1-4900-9a33-7be8941ad73d" /></td>
            <td><img width="100%" src="https://github.com/user-attachments/assets/9e3997ae-206b-4ae4-a352-876863f7eb7a" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/611d3919-128a-464f-b5c9-2a8bd936154f" /></td>
            <td><img width="100%" src="https://github.com/user-attachments/assets/b3b18101-635c-4d52-939e-25997a560b81" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/d83eefb0-7c3f-4149-af73-e33bf9303898" /></td>
            <td><img width="100%" src="https://github.com/user-attachments/assets/c74d5377-506c-42a6-8826-31d5d733fae4" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/2f49ece6-ca7e-4c46-827a-e151a1902a5b" /></td>
            <td><img width="100%" src="https://github.com/user-attachments/assets/77b831d0-7f42-41fe-9d5b-fda2f377d44e" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/92da7e12-594f-4f29-aa6c-db27dd7883fc" /></td>
            <td><img width="100%" src="https://github.com/user-attachments/assets/13badb71-2005-464e-9f01-47f97a4246b5" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/93c60bef-6e2e-4592-91a2-1e190816f2c5" /></td>
            <td><img width="100%" src="https://github.com/user-attachments/assets/5196ea56-7c8d-4b4b-9286-531e7c81c604" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/729de52f-0d3c-4da9-bbdc-ec28c2a16952" /></td>
            <td><img width="100%" src="https://github.com/user-attachments/assets/a6f128a9-a152-4ec8-85bd-a72f0c737313" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/49d875c4-1e73-4a11-9c41-042ad776da6b" /></td>
            <td><img width="100%" src="https://github.com/user-attachments/assets/5b264707-9fce-491a-9f7b-07359c0e0b49" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/8b4cee8c-0fb5-41cb-9a45-1c416fe2e7cf" /></td>
            <td><img width="100%" src="https://github.com/user-attachments/assets/4aada4a1-eba4-49a8-975b-56cd46d5c339" /></td>
        </tr>
        <tr>
            <td><img width="100%" src="https://github.com/user-attachments/assets/f97b4905-8b13-4139-b36b-c5334db3eeb9" /></td>
            <td><img width="100%" src="https://github.com/user-attachments/assets/c33353f2-9d69-48d1-86b1-87b6142b8bd9" /></td>
        </tr>
    </tbody>
</table>
<h2>📄 Ліцензія</h2>
<p>
    <a href="./LICENSE" target="_blank">MIT License</a>
</p>
