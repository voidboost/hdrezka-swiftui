<h1>🎬 HDrezka для macOS / iPadOS (неофіційний клієнт)</h1>
<p>Неофіційний клієнт HDrezka для macOS та iPadOS. <br>Потрібна <b>macOS 13 Ventura / iPadOS 18</b> або новіша.</p>
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
        <a href="https://voidboost.github.io/hdrezka-releases/HDrezka 1.0.22.dmg" target="_blank">Завантажити останню версію (macOS 15 Sequoia або новіша)</a>
    </li>
    <li>
        <span> 💻 </span>
        <a href="https://voidboost.github.io/hdrezka-releases/HDrezka 1.0.10.dmg" target="_blank">Завантажити стабільну версію (macOS 13 Ventura або новіша)</a>
    </li>
    <li>
        <span> 📱 </span>
        <a href="https://voidboost.github.io/hdrezka-releases/HDrezka 1.0.22.ipa" target="_blank">Завантажити останню версію (iPadOS 18 або новіша)</a>
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
<h2>📄 Ліцензія</h2>
<p>
    <a href="./LICENSE" target="_blank">MIT License</a>
</p>
