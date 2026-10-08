NSQC4.RegisterModule("course", function()

ns_llua = ns_llua or {}
ns_llua['lua'] = ns_llua['lua'] or {}

ns_llua['lua'][1] = {
    type = "info",
    title = "Введение в Lua",
    content = [=[
<h>Введение в Lua</h>
Lua — это легковесный, динамический язык программирования, основанный на таблицах. Он поддерживает разные стили программирования: императивный, объектно-ориентированный (через таблицы и метатаблицы) и функциональный. Имеет всего несколько типов данных, а основной структурой данных является таблица.

Чаще всего его используют как встраиваемый скриптовый язык в играх и приложениях, но также он работает и самостоятельно — например, в консольных утилитах или веб-серверах.

<h>Переменные и область видимости</h>
В Lua 5.1 переменные могут быть глобальными или локальными.

<t>Локальные переменные</t> — объявляются с ключевым словом <k>local</k>, доступны только в пределах своего блока. Использование локальных переменных делает код быстрее.

<t>Глобальные переменные</t> — объявляются без <k>local</k> и доступны отовсюду, но их использование считается плохой практикой.

<t>Примеры кода:</t>
<code>
<cm>-- Объявление локальной переменной</cm>
<kw>local</kw> userName <op>=</op> <st>'Высшая'</st>

<cm>-- Объявление глобальной переменной</cm>
userName <op>=</op> <st>"Шеф"</st>

<cm>-- Константы принято писать заглавными</cm>
<kw>local</kw> MAX_USERS <op>=</op> <nu>100</nu>
</code>

<w>Примечание:</w> По соглашению, константы (значения, которые не должны меняться) записывают в ВЕРХНЕМ_РЕГИСТРЕ. Хотя язык не запрещает их изменять, хорошей практикой считается этого не делать.
]=],
}

ns_llua['lua'][2] = {
    type = "info",
    title = "Комментарии в Lua",
    content = [=[
<h>Комментарии в Lua</h>
Комментарии — это текст в коде, который игнорируется интерпретатором. Они нужны для пояснения логики, временного отключения кода или оставления заметок для других разработчиков.

<h>Однострочные комментарии</h>
Однострочный комментарий начинается с двух дефисов <c>--</c>. Всё, что находится после них до конца строки, игнорируется при выполнении.

<t>Примеры:</t>
<code>
<cm>-- Это комментарий, он не выполнится</cm>
<kw>local</kw> x <op>=</op> <nu>10</nu>  <cm>-- А это комментарий после кода</cm>
</code>

<h>Многострочные комментарии</h>
Для комментирования больших блоков кода используются многострочные комментарии. Они начинаются с <c>--[[</c> и заканчиваются <c>]]</c>. Всё, что находится между ними, будет проигнорировано.

<t>Пример:</t>
<code>
<cm>--[[
Этот код не выполнится:
local a = 5
local b = 10
print(a + b)
]]</cm>

<cm>-- А это уже выполнится</cm>
<kw>print</kw><op>(</op><st>"Привет, мир!"</st><op>)</op>
</code>
]=],
}

ns_llua['lua'][3] = {
    type = "info",
    title = "Команда /run",
    content = [=[
<h>Команда /run</h>

<t>Назначение:</t> выполнение Lua-кода прямо в игре без создания аддона.

<t>Синтаксис:</t>
<code>
<kw>/run</kw> код
</code>

<t>Примеры для практики:</t>
<code>
<cm>-- Вывод сообщения в чат</cm>
<kw>/run</kw> <kw>print</kw><op>(</op><st>"Hello, World!"</st><op>)</op>

<cm>-- Математические операции</cm>
<kw>/run</kw> <kw>print</kw><op>(</op><nu>2</nu> <op>+</op> <nu>2</nu> <op>*</op> <nu>3</nu><op>)</op>

<cm>-- Создание глобальной переменной</cm>
<kw>/run</kw> myVar <op>=</op> <st>"Привет"</st>

<cm>-- Использование созданной переменной</cm>
<kw>/run</kw> <kw>print</kw><op>(</op>myVar<op>)</op>

<cm>-- Несколько команд в одной строке</cm>
<kw>/run</kw> <kw>local</kw> a<op>=</op><nu>5</nu><op>;</op> <kw>local</kw> b<op>=</op><nu>10</nu><op>;</op> <kw>print</kw><op>(</op>a<op>+</op>b<op>)</op>
</code>

<h>Локальные и глобальные переменные в /run</h>

<t>Важное различие:</t>
<code>
<cm>-- Команда 1: создаём локальную переменную</cm>
<kw>/run</kw> <kw>local</kw> x <op>=</op> <nu>10</nu>

<cm>-- Команда 2: пытаемся вывести x</cm>
<kw>/run</kw> <kw>print</kw><op>(</op>x<op>)</op>  <cm>-- nil! Переменная не существует</cm>
</code>

<t>Почему x равен nil?</t> Потому что <k>local</k> создаёт переменную только внутри текущего блока. Когда команда завершается — переменная уничтожается.

<code>
<cm>-- Команда 1: создаём глобальную переменную</cm>
<kw>/run</kw> y <op>=</op> <nu>20</nu>

<cm>-- Команда 2: выводим y</cm>
<kw>/run</kw> <kw>print</kw><op>(</op>y<op>)</op>  <cm>-- 20! Переменная доступна</cm>
</code>

<t>Почему y доступен?</t> Без <k>local</k> переменная попадает в глобальную область и живёт до перезагрузки интерфейса.

<w>Запомни:</w> Локальные переменные живут только внутри одной команды /run. Глобальные — сохраняются между командами.

<h>Команда /dump</h>

<t>Назначение:</t> улучшенный вывод для отладки. Показывает значение и его структуру.

<t>Отличия от print:</t>
- <k>/dump</k> показывает содержимое таблиц и функций
- Удобен для проверки переменных
- Выводит данные в структурированном виде

<t>Примеры вывода:</t>
<code>
<cm>-- dump с таблицей — показывает структуру</cm>
<kw>/dump</kw> <op>{</op><st>"меч"</st><op>,</op> <st>"щит"</st><op>}</op>

<cm>Dump: value={</cm>
<cm>[1]="меч",</cm>
<cm>[2]="щит"</cm>
<cm>}</cm>
</code>

<h>Функции WoW API</h>
В игре доступно множество встроенных функций:

<code>
<cm>-- Показать имя персонажа</cm>
<kw>/run</kw> <kw>print</kw><op>(</op>UnitName<op>(</op><st>"player"</st><op>)</op><op>)</op>

<cm>-- Показать текущее здоровье</cm>
<kw>/run</kw> <kw>print</kw><op>(</op>UnitHealth<op>(</op><st>"player"</st><op>)</op><op>)</op>

<cm>-- Показать координаты</cm>
<kw>/run</kw> <kw>local</kw> x<op>,</op>y <op>=</op> GetPlayerMapPosition<op>(</op><st>"player"</st><op>)</op><op>;</op> <kw>print</kw><op>(</op>x<op>)</op><op>;</op> <kw>print</kw><op>(</op>y<op>)</op>
</code>

<t>Советы:</t>
- Стрелки вверх/вниз — история команд
- Несколько команд разделяйте <k>;</k> (точка с запятой)

<w>Важно:</w> Глобальные переменные сохраняются до перезагрузки интерфейса (/reload). Это позволяет использовать их для экспериментов и тестов!
]=],
}

ns_llua['lua'][4] = {
    type = "info",
    title = "Типы данных в Lua",
    content = [=[
<h>Типы данных в Lua</h>
Lua имеет 8 основных типов данных. Понимание типов — основа работы с переменными.

<h>nil — отсутствие значения</h>
<t>nil</t> означает "ничего". Единственное значение типа nil.

<code>
<kw>local</kw> empty <op>=</op> <kw>nil</kw>
<kw>local</kw> another  <cm>-- без значения будет nil</cm>
</code>

<h>boolean — логический тип</h>
Два значения: <k>true</k> (истина) и <k>false</k> (ложь).

<code>
<kw>local</kw> isAlive <op>=</op> <kw>true</kw>
<kw>local</kw> isDead <op>=</op> <kw>false</kw>
</code>

<w>Внимание:</w> Только <k>false</k> и <k>nil</k> считаются ложными. 0 и "" — это true!

<h>number — числа (БЕЗ кавычек!)</h>
<t> Золотое правило:</t> Числа пишутся <w>БЕЗ</w> кавычек.

<code>
<kw>local</kw> integer <op>=</op> <nu>42</nu>
<kw>local</kw> float <op>=</op> <nu>3.14</nu>
<kw>local</kw> negative <op>=</op> <op>-</op><nu>10</nu>
</code>

<h>string — строки (В КАВЫЧКАХ!)</h>
<t>Золотое правило:</t> Строки пишутся <w>СТРОГО В</w> кавычках.

<code>
<kw>local</kw> single <op>=</op> <st>'Привет'</st>
<kw>local</kw> double <op>=</op> <st>"Мир"</st>
</code>

<h>Число vs Строка</h>
Даже если <k>print</k> выводит их одинаково, для Lua это РАЗНЫЕ вещи:

<code>
<cm>-- ЧИСЛО 777</cm>
<kw>local</kw> num <op>=</op> <nu>777</nu>
<kw>print</kw><op>(</op>num<op>)</op>           <cm>-- 777</cm>
<kw>print</kw><op>(</op><kw>type</kw><op>(</op>num<op>)</op><op>)</op>      <cm>-- "number"</cm>

<cm>-- СТРОКА "777"</cm>
<kw>local</kw> str <op>=</op> <st>"777"</st>
<kw>print</kw><op>(</op>str<op>)</op>           <cm>-- 777</cm>
<kw>print</kw><op>(</op><kw>type</kw><op>(</op>str<op>)</op><op>)</op>      <cm>-- "string"</cm>
</code>

<h>Фишка Lua: Автоприведение</h>
Lua умная — сама превращает строки в числа и наоборот, смотря по оператору:

<code>
<cm>-- Сложение: строка -> число</cm>
<kw>print</kw><op>(</op><st>"777"</st> <op>+</op> <nu>1</nu><op>)</op>    <cm>-- 778 верно</cm>

<cm>-- Конкатенация: число -> строка</cm>
<kw>print</kw><op>(</op><nu>777</nu> <op>..</op> <nu>1</nu><op>)</op>     <cm>-- "7771" верно</cm>
</code>

<h>Когда будет ОШИБКА?</h>
Автоприведение работает только если строка похожа на число:

<code>
<kw>print</kw><op>(</op><st>"5"</st> <op>+</op> <nu>10</nu><op>)</op>      <cm>-- 15 верно</cm>
<kw>print</kw><op>(</op><st>"Привет"</st> <op>+</op> <nu>10</nu><op>)</op>  <cm>-- ОШИБКА!</cm>
</code>

<h>table — таблицы</h>
Самый мощный тип данных. И массив, и словарь одновременно.

<code>
<cm>-- Как массив</cm>
<kw>local</kw> items <op>=</op> <op>{</op><st>"меч"</st><op>,</op> <st>"щит"</st><op>,</op> <st>"зелье"</st><op>}</op>
<kw>print</kw><op>(</op>items<op>[</op><nu>1</nu><op>]</op><op>)</op>  <cm>-- "меч"</cm>

<cm>-- Как словарь</cm>
<kw>local</kw> player <op>=</op> <op>{</op>
name <op>=</op> <st>"Герой"</st><op>,</op>
level <op>=</op> <nu>10</nu>
<op>}</op>
<kw>print</kw><op>(</op>player<op>.</op>name<op>)</op>  <cm>-- "Герой"</cm>
</code>

<h>Функция type()</h>
Возвращает строку с названием типа переменной:

<code>
<kw>print</kw><op>(</op><kw>type</kw><op>(</op><nu>42</nu><op>)</op><op>)</op>        <cm>-- "number"</cm>
<kw>print</kw><op>(</op><kw>type</kw><op>(</op><st>"текст"</st><op>)</op><op>)</op>   <cm>-- "string"</cm>
<kw>print</kw><op>(</op><kw>type</kw><op>(</op><kw>true</kw><op>)</op><op>)</op>      <cm>-- "boolean"</cm>
<kw>print</kw><op>(</op><kw>type</kw><op>(</op><op>{}</op><op>)</op><op>)</op>        <cm>-- "table"</cm>
<kw>print</kw><op>(</op><kw>type</kw><op>(</op><kw>nil</kw><op>)</op><op>)</op>       <cm>-- "nil"</cm>
</code>
]=],
}

ns_llua['lua'][5] = {
    type = "vartest",
    title = "Практика: Типы переменных",
    helpModules = {4, 3},
    tasks = {
        { var = "testNumber", type = "number",  desc = "Создай глобальную переменную testNumber с любым числом" },
        { var = "testString", type = "string",  desc = "Создай глобальную переменную testString с любой строкой" },
        { var = "testBool",   type = "boolean", desc = "Создай глобальную переменную testBool со значением true или false" },
        { var = "testNil",    type = "nil",     desc = "Обнули переменную testNil (сделай /run testNil = nil)" },
        { var = "testTable",  type = "table",   desc = "Создай глобальную переменную testTable с пустой таблицей {}" },
    },
}

ns_llua['lua'][6] = {
    type = "commenttest",
    title = "Практика: Комментарии",
    helpModules = {2},
    requiredPrintCount = 5,
    instruction = "Закомментируй строки 2 и 4, чтобы они не выполнялись. Остальные строки должны работать.",
    initialCode = [=[
print("Строка 1 - должна работать")
print("Строка 2 - закомментируй меня")
print("Строка 3 - должна работать")
print("Строка 4 - закомментируй меня")
print("Строка 5 - должна работать")
]=],
    expectedOutput = "Строка 1 - должна работать\nСтрока 3 - должна работать\nСтрока 5 - должна работать",
}

ns_llua['lua'][7] = {
    type = "info",
    title = "Функция print и форматирование",
    content = [=[
<h>Функция print</h>
<t>print</t> — это основная функция для вывода информации в чат. Она принимает любое количество аргументов и выводит их через табуляцию.

<t>Базовое использование:</t>
<code>
-- Вывод одного значения
print("Привет, мир!")

-- Вывод нескольких значений
print("Игрок:", "Герой", "Уровень:", 10)

-- Вывод чисел и результатов вычислений
print(5 + 3)
</code>

<h>Синтаксический сахар</h>
В Lua можно вызвать print без скобок, если аргумент один и это строка или таблица.

<code>
print "Привет"
print 'Привет'
print [[Привет]]
</code>

<w>Важно:</w> В заданиях курса лучше использовать вариант со скобками: <k>print(...)</k>.

<h>Конкатенация строк</h>
<t>Оператор ..</t> склеивает строки.

<code>
local name = "Герой"
local level = 10

print("Игрок " .. name .. " достиг " .. level .. " уровня")
print("Игрок", name, "достиг", level, "уровня")
</code>

<h>string.format</h>
<t>string.format</t> позволяет собрать строку по шаблону.

<t>Основные заполнители:</t>
- <k>%s</k> — строка
- <k>%d</k> — целое число
- <k>%.2f</k> — число с двумя знаками после запятой

<code>
local name = "Артас"
local level = 80

local message = string.format("%s (ур. %d)", name, level)
print(message)

print(string.format("Золото: %.2f", 1234.5678))
</code>
]=],
}

ns_llua['lua'][8] = {
    type = "printtest",
    title = "Практика: Простой print",
    helpModules = {7, 4},
    content = [=[
<h>Практика: простой print</h>
]=],
    tasks = {
        {
            desc = "Выведи фразу 'HELLO_WOW_123' через print",
            hint = "Используй /run print(\"HELLO_WOW_123\") или /run print('HELLO_WOW_123')",
            pattern = "HELLO_WOW_123",
            expectedExpression = {
                'print("HELLO_WOW_123")',
                "print('HELLO_WOW_123')",
            },
        },
        {
            desc = "Выведи число 777 через print",
            hint = "Используй /run print(777)",
            pattern = "777",
            expectedExpression = "print(777)",
        },
        {
            desc = "Выведи строку '777' через print",
            hint = "Используй /run print(\"777\") или /run print('777')",
            pattern = "777",
            expectedExpression = {
                'print("777")',
                "print('777')",
            },
        },
        {
            desc = "Выведи фразу 'SIMPLE_TEST_OK' через print",
            hint = "Используй /run print(\"SIMPLE_TEST_OK\") или /run print('SIMPLE_TEST_OK')",
            pattern = "SIMPLE_TEST_OK",
            expectedExpression = {
                'print("SIMPLE_TEST_OK")',
                "print('SIMPLE_TEST_OK')",
            },
        },
    },
}

ns_llua['lua'][9] = {
    type = "printtest",
    title = "Практика: Конкатенация",
    helpModules = {7},
    content = [=[
<h>Практика: конкатенация</h>
]=],
    tasks = {
        {
            desc = "Выведи фразу 'FOX BRAVO CHARLIE' через конкатенацию трёх слов с пробелами",
            hint = "Используй /run print(\"FOX\" .. \" BRAVO \" .. \"CHARLIE\")",
            pattern = "FOX BRAVO CHARLIE",
            requireConcat = true,
            requiredConcatCount = 2,
        },
        {
            desc = "Выведи фразу 'WOW-VERSION-335' через конкатенацию с дефисами",
            hint = "Используй /run print(\"WOW-\" .. \"VERSION-\" .. \"335\")",
            pattern = "WOW-VERSION-335",
            requireConcat = true,
            requiredConcatCount = 2,
        },
        {
            desc = "Выведи фразу 'ALPHA BETA GAMMA' через конкатенацию трёх частей с пробелами",
            hint = "Используй /run print(\"ALPHA\" .. \" BETA \" .. \"GAMMA\")",
            pattern = "ALPHA BETA GAMMA",
            requireConcat = true,
            requiredConcatCount = 2,
        },
    },
}

ns_llua['lua'][10] = {
    type = "info",
    title = "Математические операторы",
    content = [=[
<h>Работа с числами</h>
<t>В Lua числа имеют тип <k>number</k>. Отдельного целочисленного типа нет: и <k>7</k>, и <k>3.14</k> — это <k>number</k>.</t>

<code>
local num1 = 7
local num2 = 10
local num3 = num1 + num2

print(num3) -- 17
</code>

<w>Числа пишутся без кавычек, строки — в кавычках.</w>

<h>Основные операции</h>
<t>Над числами можно выполнять сложение, вычитание, умножение, деление, остаток от деления и возведение в степень.</t>

<code>
local a = 7
local b = 2

print(a + b) -- 9 (сложение)
print(a - b) -- 5 (вычитание)
print(a * b) -- 14 (умножение)
print(a / b) -- 3.5 (деление)
print(a % b) -- 1 (остаток от деления)
print(a ^ b) -- 49 (возведение в степень)
print(-a)    -- -7 (унарный минус - смена знака)
</code>

<t>Деление <k>/</k> всегда возвращает число с дробной частью.</t>
<t>Если нужна целая часть, используй <k>math.floor</k>:</t>

<code>
print(math.floor(7 / 2)) -- 3
</code>

<h>Порядок операций</h>
<t>Сначала выполняются умножение, деление и остаток, затем сложение и вычитание. Скобки меняют порядок.</t>

<code>
local num1 = 2 + 3 * 4
local num2 = (2 + 3) * 4

print(num1) -- 14
print(num2) -- 20
</code>

<h>Преобразование строки в число</h>
<t>Для явного преобразования строки в число используется <k>tonumber</k>.</t>

<code>
local s = "1992"
local year = tonumber(s)

print(year + 1) -- 1993
</code>

<t>В математических операциях Lua часто сама превращает строку в число:</t>

<code>
print("5" + 2) -- 7
</code>

<w>Если строка не похожа на число, будет ошибка:</w>

<code>
print("Привет" + 2) -- ошибка
</code>

<h>tonumber: когда возвращает nil</h>
<t>Функция <k>tonumber</k> пытается сделать из значения число. Важно не то, какого типа значение на входе, а то, получилось ли превращение.</t>
<t>Если получилось — вернётся число. Если не получилось — вернётся <k>nil</k>.</t>

<code>
print(tonumber("25"))   -- 25: строку "25" можно прочитать как число
print(tonumber("3.5"))  -- 3.5: дробная строка тоже превращается
print(tonumber(7))      -- 7: на входе уже число, tonumber вернул его как есть
print(tonumber("bad"))  -- nil: из "bad" число не сделать
print(tonumber("abc"))  -- nil: из "abc" число не сделать
</code>

<w>Главное:</w> <k>nil</k> здесь — это ответ «это не число». Не ошибка, не ноль, не пустая строка — именно <k>nil</k>.

<h>Зачем это нужно</h>
<t>Так как число в условии — истина, а <k>nil</k> — ложь, результатом <k>tonumber</k> можно проверять «а это вообще число?».</t>

<code>
local price = tonumber(v)   -- превращаем: число или nil
if price then               -- число = истина, nil = ложь
    print("это число")      -- выполнится только если превращение удалось
end                         -- закрываем условие
</code>

<t>Проверять саму строку через <k>if v then</k> бесполезно: любая строка, даже "bad", в Lua — истина. Разницу между "5" (цена текстом) и "bad" (мусор) видит только <k>tonumber</k>, потому что тип у обеих — <k>string</k>.</t>

<h>Короткое правило</h>
<t>Не гадай по типу, строка там или число. Скармливай значение <k>tonumber</k> и верь ответу: число — значит получилось, <k>nil</k> — значит нет. Один <k>tonumber</k> закрывает и строку-цену ("5"), и число-цену (7), и мусор ("bad").</t>

<h>Преобразование числа в строку</h>
<t>Для явного преобразования числа в строку используется <k>tostring</k>.</t>

<code>
local num = 17
local s = tostring(num)

print(s) -- "17"
</code>

<t>Оператор конкатенации <k>..</k> тоже автоматически превращает число в строку:</t>

<code>
print("Уровень: " .. 80) -- Уровень: 80
</code>

<h>Частые ошибки</h>
<code>
local num = 777
local str = "777"

print(type(num)) -- number
print(type(str)) -- string
</code>

<t>Основные ошибки:</t>
- записать число в кавычках и ожидать числовое поведение;
- ждать целое число после деления <k>/</k>;
- пытаться сложить число со строкой, которая не является числом;
- проверять саму строку через <k>if v then</k> вместо результата <k>tonumber(v)</k>: строка всегда истина, а «это число или нет» решает только <k>tonumber</k>.
]=],
}

ns_llua['lua'][11] = {
    type = "commenttest",
    title = "Практика: Множественное присваивание",
    helpModules = {1, 3, 4},

    preloadVars = {
        {var = "a", value = 1, desc = "a = 1"},
        {var = "b", value = 2, desc = "b = 2"},
    },

    content = [=[
<h>Множественное присваивание</h>
<t>В Lua можно присваивать значения сразу нескольким переменным в одной строке.</t>

<code>
x, y = 10, 20
</code>

<t>Сначала Lua вычисляет все выражения справа от знака равно, а затем присваивает результаты переменным слева.</t>

<code>
x, y = x + 1, y * 2
</code>

<t>Если справа значений больше, чем слева, лишние значения отбрасываются.</t>
<t>Если слева переменных больше, оставшиеся получают nil.</t>

<code>
local a, b = 1, 2, 3
local c, d = 1
</code>

<t>Эта особенность позволяет обменивать значения переменных без дополнительной переменной.</t>
]=],

    instruction = [=[
<h>Множественное присваивание</h>
<t>В Lua можно присваивать значения сразу нескольким переменным в одной строке.</t>

<code>
x, y = 10, 20
</code>

<t>Сначала Lua вычисляет все выражения справа от знака равно, а затем присваивает результаты переменным слева.</t>

<code>
x, y = x + 1, y * 2
</code>

<t>Если справа значений больше, чем слева, лишние значения отбрасываются.</t>
<t>Если слева переменных больше, оставшиеся получают nil.</t>

<h>Задание</h>
<t>Есть переменные:</t>

<code>
a = 1
b = 2
</code>

<t>Напиши одну строку, которая поменяет значения переменных <k>a</k> и <k>b</k> местами.</t>
<t>Нельзя использовать <k>local</k>, дополнительные переменные и несколько строк.</t>
]=],

    initialCode = [=[
-- Напиши здесь одну строку
]=],

    requireKeywords = {
        "a",
        "b",
        "=",
        ",",
    },

    onlyCodePatterns = true,
    singleLine = true,

    checkCode = function()
        return _G.a == 2 and _G.b == 1
    end,
}

ns_llua['lua'][12] = {
    type = "printtest",
    title = "Практика: GetAchievementInfo и преобразование типов",
    helpModules = {10, 11},

    preloadVars = {
        {
            var = "achieveId",
            value = 944,
            desc = "achieveId = 944 (number)",
        },
        {
            var = "achieveIdStr",
            value = "944",
            desc = 'achieveIdStr = "944" (string)',
        },
        {
            var = "exampleId",
            value = 521,
            desc = "exampleId = 521 (number)",
        },
        {
            var = "exampleIdStr",
            value = "521",
            desc = 'exampleIdStr = "521" (string)',
        },
        {
            var = "achieveName",
            value = "В том тоннеле меня любят!",
            desc = 'achieveName = "В том тоннеле меня любят!" (string)',
        },
        {
            var = "achievePoints",
            value = 15,
            desc = "achievePoints = 15 (number)",
        },
        {
            var = "achieveCompleted",
            value = false,
            desc = "achieveCompleted = false (boolean)",
        },
    },

    content = [=[
<h>Практика: GetAchievementInfo и преобразование типов</h>
<t>В игре есть функция <k>GetAchievementInfo</k>. Она возвращает информацию о достижении.</t>

<t>Посмотрим, как это работает, на примере достижения 521:</t>

<code>
/dump GetAchievementInfo(521)
</code>

<code>
[1]=521,
[2]="Превознесение среди 15 фракций",
[3]=10,
[4]=false,
[8]="Добейтесь того, чтобы вас превозносили 15 фракций.",
[9]=0,
[10]="Interface\Icons\Achievement_Reputation_03",
[11]=""
</code>

<t>То есть функция возвращает сразу несколько значений: ID, название, очки и другие данные.</t>

<t>Чтобы получить нужные значения, используй множественное присваивание:</t>

<code>
local id, name, points = GetAchievementInfo(521)
</code>

<t>В этом задании есть несколько переменных. Среди них есть числа, строки и boolean (узнай какой тип у какой):</t>

<code>
/run print(achieveId, type(achieveId))
/run print(achieveIdStr, type(achieveIdStr))
/run print(exampleId, type(exampleId))
/run print(exampleIdStr, type(exampleIdStr))
/run print(achieveName, type(achieveName))
/run print(achievePoints, type(achievePoints))
/run print(achieveCompleted, type(achieveCompleted))
</code>

<h>Задание 1</h>
<t>Выведи название достижения 944.</t>
<t>Не вставляй число 944 вручную. Используй подходящую переменную, в которой уже лежит число.</t>

<code>
/run local id, name = GetAchievementInfo(___); print(name)
</code>

<h>Задание 2</h>
<t>Снова выведи название достижения 944.</t>
<t>В этот раз используй переменную <k>achieveIdStr</k>. Это строка, поэтому её нужно преобразовать в число.</t>

<code>
/run local id, name = GetAchievementInfo(___); print(name)
</code>
]=],

    tasks = {
        {
            desc = "Выведи название достижения 944, используя правильную переменную",
            hint = "Используй переменную achieveId. Число 944 вручную вставлять нельзя.",
            pattern = "В том тоннеле меня любят!",

            requireKeywords = {
                "local",
                "GetAchievementInfo(achieveId)",
                "print",
            },

            forbidKeywords = {
                "944",
                "achieveIdStr",
                "achieveName",
            },
        },

        {
            desc = "Выведи название достижения 944, преобразовав переменную в число",
            hint = "achieveIdStr — это строка. Её нужно преобразовать в число.",
            pattern = "В том тоннеле меня любят!",

            requireKeywords = {
                "local",
                "GetAchievementInfo",
                "tonumber(achieveIdStr)",
                "print",
            },

            forbidKeywords = {
                "944",
                "achieveName",
            },
        },

    },
}

ns_llua['lua'][13] = {
    type = "printtest",
    title = "Практика: Числа и математика",
    helpModules = {10},
    content = [=[
<h>Практика: числа и математика</h>
]=],
    tasks = {
        {
            desc = "Выведи результат умножения 6 * 7",
            hint = "Используй /run print(6 * 7)",
            pattern = "42",
            expectedExpression = {
                "print(6*7)",
                "print(7*6)",
            },
        },
        {
            desc = "Выведи результат выражения 100 - 25",
            hint = "Используй /run print(100 - 25)",
            pattern = "75",
            expectedExpression = "print(100-25)",
        },
        {
            desc = "Выведи результат выражения 15 + 30 * 2",
            hint = "Используй /run print(15 + 30 * 2)",
            pattern = "75",
            expectedExpression = "print(15+30*2)",
        },
    },
}

ns_llua['lua'][14] = {
    type = "vartest",
    title = "Практика: string.format с переменными",
    helpModules = {7},

    content = [=[
<h>Что такое string.format</h>
<t>string.format</t> — это функция, которая собирает строку по шаблону.

В шаблоне есть специальные метки, а после шаблона перечисляются значения, которые на эти метки подставятся.

<t>Основные метки:</t>
- <k>%s</k> — строка
- <k>%d</k> — целое число
- <k>%.2f</k> — дробное число с двумя знаками после запятой

<t>Зачем это нужно:</t>
Чтобы не склеивать строку кусками через <k>..</k>, а сразу написать красивый и понятный шаблон.

<h>Пример</h>
Выполни готовую команду:

<code>
/run local itemName = "Меч"; local itemLevel = 25; print(string.format("Предмет: %s, уровень: %d", itemName, itemLevel))
</code>

<t>Что здесь происходит:</t>
- Шаблон: <s>"Предмет: %s, уровень: %d"</s>
- Первый аргумент после шаблона: <k>itemName</k>
- Второй аргумент после шаблона: <k>itemLevel</k>
- Метка <k>%s</k> заменяется на <k>itemName</k>
- Метка <k>%d</k> заменяется на <k>itemLevel</k>

<t>Вывод будет:</t>

<code>
Предмет: Меч, уровень: 25
</code>

<w>Важно:</w> Порядок аргументов имеет значение.

Первая метка получает первую переменную, вторая метка — вторую, и так далее.

<c>Здесь использованы local-переменные. Они живут только внутри одной команды /run.</c>

<h>Тест</h>
<t>Теперь создай переменные героя и выведи строку о герое с помощью string.format.</t>
]=],

    tasks = {
        {
            var = "heroName",
            desc = 'Создай глобальную переменную heroName = "Артас"',
            check = function(value)
                return type(value) == "string" and value == "Артас"
            end,
        },
        {
            var = "heroTitle",
            desc = 'Создай глобальную переменную heroTitle = "Король-лич"',
            check = function(value)
                return type(value) == "string" and value == "Король-лич"
            end,
        },
        {
            var = "heroLevel",
            desc = "Создай глобальную переменную heroLevel = 80",
            check = function(value)
                return type(value) == "number" and value == 80
            end,
        },
        {
            var = "heroHP",
            desc = "Создай глобальную переменную heroHP = 25000",
            check = function(value)
                return type(value) == "number" and value == 25000
            end,
        },
    },

    formatTask = {
        instruction = [=[
Используя string.format, выведи строку:

"Герой Артас (Король-лич) - Уровень: 80, HP: 25000"

Шаблон команды (заполни пропуски вместо ___ именами переменных):

/run print(string.format("Герой %s (%s) - Уровень: %d, HP: %d", ___, ___, ___, ___))

Подсказка:
- первый %s — имя героя;
- второй %s — титул героя;
- первый %d — уровень;
- второй %d — здоровье.
]=],
        pattern = "Герой Артас (Король-лич) - Уровень: 80, HP: 25000",
        requireKeywords = {
            "print",
            "string.format",
        },
    },
}

ns_llua['lua'][15] = {
    type = "info",
    title = "Сравнения и логические значения",
    content = [=[
<h>Сравнения и логические значения</h>
<t>Операторы сравнения нужны, чтобы сравнивать значения между собой. Результатом сравнения всегда является <k>boolean</k> — <k>true</k> или <k>false</k>.</t>
<code>
local result = 10 > 3
print(result)       -- true
print(type(result)) -- boolean
</code>

<h>1. Оператор равно</h>
<t>Записывается как <k>==</k>.</t>
<t>Правило:</t> возвращает <k>true</k>, если левое и правое значения равны.
<code>
print(5 == 5)         -- true
print(5 == 6)         -- false
print("Меч" == "Меч") -- true
print("Меч" == "Щит") -- false
</code>
<w>Важно:</w> один знак <k>=</k> — это присваивание, а два знака <k>==</k> — это сравнение.
<code>
local level = 80     -- присваивание
print(level == 80)   -- сравнение, вернёт true
</code>

<h>2. Оператор не равно</h>
<t>Записывается как <k>~=</k>.</t>
<t>Правило:</t> возвращает <k>true</k>, если значения НЕ равны.
<code>
print(7 ~= 7)         -- false
print(7 ~= 8)         -- true
print("лук" ~= "меч") -- true
</code>

<h>3. Оператор больше</h>
<t>Записывается как <k>></k>.</t>
<t>Правило:</t> возвращает <k>true</k>, если левое значение больше правого.
<code>
print(10 > 3) -- true
print(3 > 10) -- false
print(5 > 5)  -- false
</code>

<h>4. Оператор меньше</h>
<t>Записывается как <k><</k>.</t>
<t>Правило:</t> возвращает <k>true</k>, если левое значение меньше правого.
<code>
print(3 < 10) -- true
print(10 < 3) -- false
print(5 < 5)  -- false
</code>

<h>5. Оператор больше или равно</h>
<t>Записывается как <k>>=</k>.</t>
<t>Правило:</t> возвращает <k>true</k>, если левое значение больше или равно правому.
<code>
print(8 >= 8) -- true
print(9 >= 8) -- true
print(7 >= 8) -- false
</code>

<h>6. Оператор меньше или равно</h>
<t>Записывается как <k><=</k>.</t>
<t>Правило:</t> возвращает <k>true</k>, если левое значение меньше или равно правому.
<code>
print(7 <= 8) -- true
print(8 <= 8) -- true
print(9 <= 8) -- false
</code>

<h>Шпаргалка по операторам сравнения</h>
<c>== — равно</c>
<c>~= — не равно</c>
<c>> — больше</c>
<c>< — меньше</c>
<c>>= — больше или равно</c>
<c><= — меньше или равно</c>

<h>Логические значения</h>
<t>Тип <k>boolean</k> имеет только два значения:</t>
<t><k>true</k> — истина.</t>
<t><k>false</k> — ложь.</t>
<code>
local isAlive = true
local isDead = false
print(type(isAlive)) -- boolean
print(type(isDead))  -- boolean
</code>

<h>Оператор not</h>
<t>Записывается как <k>not</k>.</t>
<t>Правило:</t> оператор <k>not</k> переворачивает логическое значение.
<t>Если значение ложное, то <k>not</k> вернёт <k>true</k>. Если значение истинное, то <k>not</k> вернёт <k>false</k>.</t>
<code>
print(not true)  -- false
print(not false) -- true
print(not nil)   -- true
</code>
<t>В Lua ложными считаются только <k>false</k> и <k>nil</k>. Поэтому числа, строки и таблицы дают <k>false</k> после <k>not</k>:</t>
<code>
print(not 0)   -- false
print(not "")  -- false
print(not {})  -- false
</code>
<w>Важно:</w> результат оператора <k>not</k> всегда имеет тип <k>boolean</k>.
<code>
local value = 0
print(type(not value)) -- boolean
</code>
<t>Пример с условием:</t>
<code>
local isDead = false
if not isDead then
    print("Персонаж жив!")
end
</code>
<t>Двойное отрицание можно использовать, чтобы превратить любое значение в <k>true</k> или <k>false</k>:</t>
<code>
print(not not 0)   -- true
print(not not nil) -- false
</code>

<h>Шпаргалка по not</h>
<c>not true = false</c>
<c>not false = true</c>
<c>not nil = true</c>
<c>not 0 = false</c>
<c>not "" = false</c>
<c>not {} = false</c>

<h>Что в Lua считается ложью</h>
<w>Очень важно:</w> в Lua только <k>false</k> и <k>nil</k> считаются ложными. Всё остальное — <k>true</k>.
<code>
if 0 then
    print("0 считается true")
end

if "" then
    print("Пустая строка считается true")
end

if {} then
    print("Пустая таблица считается true")
end
</code>

<h>nil и false — не одно и то же</h>
<t><k>nil</k> означает отсутствие значения, а <k>false</k> — логическую ложь. При сравнении они не равны.</t>
<code>
print(nil == false) -- false
print(nil ~= false) -- true
</code>

<h>Сравнение чисел и строк</h>
<t>Число и строка с таким же текстом — это разные значения.</t>
<code>
print(777 == "777") -- false
print(type(777))    -- number
print(type("777"))  -- string
</code>
<t>Если строку нужно сравнить как число, её можно преобразовать:</t>
<code>
print(tonumber("777") == 777) -- true
</code>

<h>Частые ошибки</h>
<w>Ошибка 1:</w> использовать один знак <k>=</k> вместо <k>==</k> в условии.
<code>
-- неправильно
if level = 80 then
    print("Максимальный уровень")
end

-- правильно
if level == 80 then
    print("Максимальный уровень")
end
</code>

<w>Ошибка 2:</w> думать, что <k>nil</k> и <k>false</k> — это одно и то же.
<code>
print(nil == false) -- false
</code>

<w>Ошибка 3:</w> сравнивать число со строкой без преобразования.
<code>
print(777 == "777")           -- false
print(tonumber("777") == 777) -- true
</code>

<w>Ошибка 4:</w> ожидать, что <k>not 0</k> даст <k>true</k>.
<t>В некоторых языках 0 считается ложью, но в Lua 0 — это <k>true</k>. Поэтому:</t>
<code>
print(not 0) -- false
</code>

<h>Где это используется</h>
<t>Сравнения чаще всего используются внутри условий <k>if</k>:</t>
<code>
local hp = 85
if hp > 60 then
    print("Боеспособен")
end
</code>
<t>Оператор <k>not</k> часто используется, чтобы проверить обратное условие:</t>
<code>
local inCombat = false
if not inCombat then
    print("Можно спокойно отдохнуть")
end
</code>
]=],
}

ns_llua['lua'][16] = {
    type = "printtest",
    title = "Практика: Сравнения",
    helpModules = {15, 4},
    content = [=[
<h>Практика: сравнения</h>
<t>Выведи результат сравнения через <k>print</k>.</t>
<t>Задания проверяются по очереди.</t>
]=],
    tasks = {
        {
            desc = "Выведи результат 5 == 5",
            hint = "Используй /run print(5 == 5)",
            pattern = "true",
            requireKeywords = {"print", "5==5"},
            forbidKeywords = {"true", "false", "nil"},
        },
        {
            desc = "Выведи результат 7 ~= 7",
            hint = "Используй /run print(7 ~= 7)",
            pattern = "false",
            requireKeywords = {"print", "7~=7"},
            forbidKeywords = {"true", "false", "nil"},
        },
        {
            desc = "Выведи результат 10 > 3",
            hint = "Используй /run print(10 > 3)",
            pattern = "true",
            requireKeywords = {"print", "10>3"},
            forbidKeywords = {"true", "false", "nil"},
        },
        {
            desc = "Выведи результат 10 < 3",
            hint = "Используй /run print(10 < 3)",
            pattern = "false",
            requireKeywords = {"print", "10<3"},
            forbidKeywords = {"true", "false", "nil"},
        },
        {
            desc = "Выведи результат 8 >= 8",
            hint = "Используй /run print(8 >= 8)",
            pattern = "true",
            requireKeywords = {"print", "8>=8"},
            forbidKeywords = {"true", "false", "nil"},
        },
        {
            desc = "Выведи результат 8 <= 7",
            hint = "Используй /run print(8 <= 7)",
            pattern = "false",
            requireKeywords = {"print", "8<=7"},
            forbidKeywords = {"true", "false", "nil"},
        },
    },
}

ns_llua['lua'][16.1] = {
    type = "commenttest",
    title = "Практика: предскажи результат сравнений",
    helpModules = {15, 4},
    preloadVars = {
        {var = "answer1", desc = "answer1 очищается перед проверкой"},
        {var = "answer2", desc = "answer2 очищается перед проверкой"},
        {var = "answer3", desc = "answer3 очищается перед проверкой"},
        {var = "answer4", desc = "answer4 очищается перед проверкой"},
        {var = "answer5", desc = "answer5 очищается перед проверкой"},
        {var = "answer6", desc = "answer6 очищается перед проверкой"},
    },
    reportVars = {
        "answer1",
        "answer2",
        "answer3",
        "answer4",
        "answer5",
        "answer6",
    },
    instruction = [=[
<h>Практика: предскажи результат</h>
<t>Ниже даны сравнения. Не нужно использовать print или сами операторы сравнения.</t>
<t>Твоя задача — заменить <k>nil</k> на <k>true</k> или <k>false</k> в каждой строке.</t>
<code>
5 == 5
7 ~= 7
10 > 3
10 < 3
8 >= 8
8 <= 7
</code>
<w>Пиши только answer1-answer6, знак =, true и false. Без точек с запятой и без операторов сравнения.</w>
]=],
    initialCode = [=[
answer1 = nil -- 5 == 5
answer2 = nil -- 7 ~= 7
answer3 = nil -- 10 > 3
answer4 = nil -- 10 < 3
answer5 = nil -- 8 >= 8
answer6 = nil -- 8 <= 7
]=],
    requireKeywords = {
        "answer1",
        "answer2",
        "answer3",
        "answer4",
        "answer5",
        "answer6",
        "=",
        "true",
        "false",
    },
    onlyCodePatterns = true,
    checkCode = function()
        return _G.answer1 == true
            and _G.answer2 == false
            and _G.answer3 == true
            and _G.answer4 == false
            and _G.answer5 == true
            and _G.answer6 == false
    end,
}

ns_llua['lua'][17] = {
    type = "info",
    title = "Простые условия if",
    content = [=[
<h>Простые условия if</h>
<t>Конструкция <k>if</k> выполняет код, если условие истинно.</t>
<code>
local hp = 80
if hp > 60 then
    print("Боеспособен")
end
</code>
<t>Если нужно выбрать один из двух вариантов, используй <k>else</k>.</t>
<code>
local hp = 40
if hp > 60 then
    print("Боеспособен")
else
    print("Нужен отдых")
end
</code>
<w>Важно:</w> Каждый <k>if</k> закрывается словом <k>end</k>.
]=],
}

ns_llua['lua'][18] = {
    type = "commenttest",
    title = "Практика: Простое условие if",
    helpModules = {17, 15},
    preloadVars = {
        {var = "playerMana", value = 40, desc = "playerMana = 40"},
    },
    instruction = [=[
<h>Практика: простое условие if</h>
<t>Переменная <k>playerMana</k> уже равна 40.</t>
<t>Напиши условие: если <k>playerMana</k> больше или равно 30, выведи <s>"Достаточно маны"</s>.</t>
<t>Иначе выведи <s>"Мало маны"</s>.</t>
<t>Выведи только одну строку.</t>
<w>Подсказка:</w> используй конструкцию if / then / else / end.
]=],
    initialCode = [=[
-- Напиши условие здесь
]=],
    expectedOutput = "Достаточно маны",
    requireKeywords = {"playerMana", ">=", "30", "if", "then", "else", "end", "print"},
}

ns_llua['lua'][19] = {
    type = "info",
    title = "Ветвление: if / elseif / else",
    content = [=[
<h>Ветвление: if / elseif / else</h>
<t>Конструкция <k>if / elseif / else</k> позволяет выбрать один из нескольких путей.</t>
<code>
local percent = 25
if percent >= 80 then
    print("Здоровье отличное!")
elseif percent >= 40 then
    print("Нужно подлечиться")
else
    print("СРОЧНО ЛЕЧИСЬ!")
end
</code>
<t>Как только одно условие сработало, остальные <k>elseif</k> и <k>else</k> пропускаются.</t>
<w>Важно:</w> <k>else</k> должен быть последним, а весь блок закрывается словом <k>end</k>.
]=],
}

ns_llua['lua'][20] = {
    type = "commenttest",
    title = "Практика: if / elseif / else",
    helpModules = {19, 17},
    preloadVars = {
        {var = "arenaRating", value = 1450, desc = "arenaRating = 1450"},
    },
    instruction = [=[
<h>Практика: if / elseif / else</h>
<t>Переменная <k>arenaRating</k> уже равна 1450.</t>
<t>Напиши условие с тремя ветками:</t>
<t>Если <k>arenaRating</k> больше или равно 1500, выведи <s>"Высокий рейтинг"</s>.</t>
<t>Иначе, если <k>arenaRating</k> больше или равно 1200, выведи <s>"Средний рейтинг"</s>.</t>
<t>Иначе выведи <s>"Низкий рейтинг"</s>.</t>
<t>Выведи только одну строку.</t>
<w>Подсказка:</w> используй конструкцию if / elseif / else / end.
]=],
    initialCode = [=[
-- Напиши условие здесь
]=],
    expectedOutput = "Средний рейтинг",
    requireKeywords = {"arenaRating", ">=", "1500", "1200", "if", "elseif", "else", "end", "print"},
}

ns_llua['lua'][21] = {
    type = "info",
    title = "Логические операторы and / or / not",
    content = [=[
<h>Логические операторы and / or / not</h>
<t>Оператор <k>and</k> возвращает <k>true</k>, только если оба условия истинны.</t>
<code>
local hp = 5000
local mana = 3000
if hp > 0 and mana > 1000 then
    print("Можно атаковать и кастовать")
end
</code>
<t>Оператор <k>or</k> возвращает <k>true</k>, если истинно хотя бы одно условие.</t>
<code>
local class = "Воин"
if class == "Воин" or class == "Паладин" then
    print("Можно носить латы!")
end
</code>
<t>Оператор <k>not</k> переворачивает логическое значение.</t>
<code>
local isDead = false
if not isDead then
    print("Персонаж жив!")
end
</code>
<h>Частая ошибка</h>
<w>Неправильно:</w>
<code>
local class = "Маг"
if class == "Воин" or "Паладин" then
    print("Можно носить латы!")
end
</code>
<t>Здесь вторая часть — просто строка <s>"Паладин"</s>, а любая строка в Lua считается <k>true</k>. Поэтому условие всегда будет истинным.</t>
<ok>Правильно:</ok>
<code>
local class = "Маг"
if class == "Воин" or class == "Паладин" then
    print("Можно носить латы!")
end
</code>
]=],
}

ns_llua['lua'][21.1] = {
    type = "info",
    title = "Присваивание через and и or",
    helpModules = {21, 15},
    content = [=[
<h>and и or возвращают значения</h>
<t>В модуле 21 мы использовали <k>and</k> и <k>or</k> внутри условий <k>if</k>. Но на самом деле эти операторы возвращают не <k>true</k>/<k>false</k>, а одно из своих значений.</t>
<h>Как работает or</h>
<t>Оператор <k>or</k> возвращает первое истинное значение. Если левая часть истинная — вернётся она. Если левая часть ложная — вернётся правая.</t>
<code>
print(5 or 10)     -- 5
print(nil or 10)   -- 10
print(false or 10) -- 10
</code>
<h>Как работает and</h>
<t>Оператор <k>and</k> возвращает первое ложное значение. Если левая часть ложная — вернётся она. Если левая часть истинная — вернётся правая.</t>
<code>
print(5 and 10)     -- 10
print(nil and 10)   -- nil
print(false and 10) -- false
</code>
<h>Запасное значение через or</h>
<t>Самый частый приём: <k>x = value or default</k>.</t>
<t>Если <k>value</k> равно <k>nil</k> или <k>false</k>, переменная получит запасное значение.</t>
<code>
local name = nil
local result = name or "Неизвестный"
print(result) -- Неизвестный
</code>
<code>
local level = 80
local result = level or 0
print(result) -- 80
</code>
<t>Это короче, чем:</t>
<code>
local result
if name == nil then
    result = "Неизвестный"
else
    result = name
end
</code>
<h>Защита через and</h>
<t>Приём: <k>x = condition and value</k>.</t>
<t>Если условие ложное, переменная получит <k>false</k> или <k>nil</k>. Если истинное — получит значение.</t>
<code>
local isAlive = true
local hp = 5000
local result = isAlive and hp
print(result) -- 5000
</code>
<code>
local isAlive = false
local hp = 5000
local result = isAlive and hp
print(result) -- false
</code>
<h>Шпаргалка</h>
<c>a or b — вернёт a, если a истинное, иначе b</c>
<c>a and b — вернёт a, если a ложное, иначе b</c>
<c>x = value or default — запасное значение</c>
]=],
}

ns_llua['lua'][21.2] = {
    type = "info",
    title = "Тернарный оператор",
    helpModules = {21, 21.1, 15},
    content = [=[
<h>Тернарный оператор</h>
<t>В Lua нет встроенного тернарного оператора как в других языках, но его можно имитировать через <k>and</k> и <k>or</k>.</t>
<h>Паттерн</h>
<code>
результат = условие and значение_если_да or значение_если_нет
</code>
<t>Как это работает:</t>
<t>1. Если условие истинное, <k>and</k> вернёт <k>значение_если_да</k>.</t>
<t>2. Затем <k>or</k> увидит истинное значение слева и вернёт его.</t>
<t>3. Если условие ложное, <k>and</k> вернёт <k>false</k>.</t>
<t>4. Затем <k>or</k> увидит ложное значение слева и вернёт <k>значение_если_нет</k>.</t>
<h>Пример</h>
<code>
local hp = 80
local status = (hp > 0) and "Жив" or "Мёртв"
print(status) -- Жив
</code>
<code>
local hp = 0
local status = (hp > 0) and "Жив" or "Мёртв"
print(status) -- Мёртв
</code>
<h>Сравнение с if/else</h>
<t>Тернарный паттерн заменяет:</t>
<code>
local status
if hp > 50 then
    status = "Жив"
else
    status = "Мёртв"
end
</code>
<t>на одну строку:</t>
<code>
local status = (hp > 50) and "Жив" or "Мёртв"
</code>
<h>Ловушка</h>
<w>Внимание:</w> если <k>значение_если_да</k> равно <k>false</k> или <k>nil</k>, паттерн сломается.
<code>
local cond = true
local result = cond and false or "запасной"
print(result) -- "запасной", хотя ожидалось false!
</code>
<t>Почему: <k>cond and false</k> вернёт <k>false</k>. Затем <k>false or "запасной"</k> вернёт <k>"запасной"</k>.</t>
<t>Поэтому тернарный паттерн безопасен, только если <k>значение_если_да</k> не может быть <k>false</k> или <k>nil</k>.</t>
<h>Когда использовать</h>
<t>- выбор из двух строковых значений;</t>
<t>- выбор из двух чисел;</t>
<t>- короткие выражения внутри return.</t>
<t>Если значения могут быть <k>false</k> или <k>nil</k> — лучше использовать обычный <k>if/else</k>.</t>
]=],
}

ns_llua['lua'][21.3] = {
    type = "commenttest",
    title = "Практика: запасное значение через or",
    helpModules = {21.1},
    preloadVars = {
        {var = "rawName", value = nil, desc = "rawName = nil"},
        {var = "rawLevel", value = 80, desc = "rawLevel = 80"},
        {var = "rawGuild", value = nil, desc = "rawGuild = nil"},
        {var = "safeName", desc = "safeName очищается перед проверкой"},
        {var = "safeLevel", desc = "safeLevel очищается перед проверкой"},
        {var = "safeGuild", desc = "safeGuild очищается перед проверкой"},
    },
    reportVars = {"safeName", "safeLevel", "safeGuild"},
    instruction = [=[
<h>Практика: запасное значение через or</h>
<t>Уже созданы переменные:</t>
<code>
rawName = nil
rawLevel = 80
rawGuild = nil
</code>
<t>Создай три глобальные переменные, используя оператор <k>or</k> для запасного значения.</t>
<t><k>safeName</k> — возьми значение из <k>rawName</k>. Если оно ложное, подставь запасное значение <s>"Неизвестный"</s>.</t>
<t><k>safeLevel</k> — возьми значение из <k>rawLevel</k>. Если оно ложное, подставь запасное значение <n>0</n>.</t>
<t><k>safeGuild</k> — возьми значение из <k>rawGuild</k>. Если оно ложное, подставь запасное значение <s>"Без гильдии"</s>.</t>
<t>Ожидаемый результат:</t>
<code>
safeName = "Неизвестный"
safeLevel = 80
safeGuild = "Без гильдии"
</code>
<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, переменные нужны глобальные.</w>
]=],
    initialCode = [=[
-- Создай safeName, safeLevel и safeGuild через or
]=],
    requireKeywords = {
        "safeName",
        "safeLevel",
        "safeGuild",
        "rawName",
        "rawLevel",
        "rawGuild",
        "or",
    },
    checkCode = function()
        return _G.safeName == "Неизвестный"
            and _G.safeLevel == 80
            and _G.safeGuild == "Без гильдии"
    end,
}

ns_llua['lua'][21.4] = {
    type = "commenttest",
    title = "Практика: and возвращает значения",
    helpModules = {21.1},
    preloadVars = {
        {var = "isAlive", value = true, desc = "isAlive = true"},
        {var = "hp", value = 5000, desc = "hp = 5000"},
        {var = "isDead", value = false, desc = "isDead = false"},
        {var = "mana", value = 3000, desc = "mana = 3000"},
        {var = "check1", desc = "check1 очищается перед проверкой"},
        {var = "check2", desc = "check2 очищается перед проверкой"},
        {var = "check3", desc = "check3 очищается перед проверкой"},
    },
    reportVars = {"check1", "check2", "check3"},
    instruction = [=[
<h>Практика: and возвращает значения</h>
<t>Уже созданы переменные:</t>
<code>
isAlive = true
hp = 5000
isDead = false
mana = 3000
</code>
<t>Создай три глобальные переменные, используя оператор <k>and</k>.</t>
<t><k>check1</k> — примени <k>and</k> между <k>hp</k> и <k>isAlive</k>.</t>
<t><k>check2</k> — примени <k>and</k> между <k>mana</k> и <k>isDead</k>.</t>
<t><k>check3</k> — примени <k>and</k> между <k>isAlive</k> и <k>isDead</k>.</t>
<t>Подумай, что вернёт <k>and</k> в каждом случае: первое ложное значение или последнее истинное.</t>
<t>Ожидаемый результат:</t>
<code>
check1 = 5000
check2 = false
check3 = false
</code>
<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, переменные нужны глобальные.</w>
]=],
    initialCode = [=[
-- Создай check1, check2 и check3 через and
]=],
    requireKeywords = {
        "check1",
        "check2",
        "check3",
        "isAlive",
        "hp",
        "isDead",
        "mana",
        "and",
    },
    checkCode = function()
        return _G.check1 == 5000
            and _G.check2 == false
            and _G.check3 == false
    end,
}

ns_llua['lua'][21.5] = {
    type = "commenttest",
    title = "Практика: предскажи результат or",
    helpModules = {21.1},
    preloadVars = {
        {var = "answer1", desc = "answer1 очищается перед проверкой"},
        {var = "answer2", desc = "answer2 очищается перед проверкой"},
        {var = "answer3", desc = "answer3 очищается перед проверкой"},
        {var = "answer4", desc = "answer4 очищается перед проверкой"},
        {var = "answer5", desc = "answer5 очищается перед проверкой"},
        {var = "answer6", desc = "answer6 очищается перед проверкой"},
    },
    reportVars = {
        "answer1",
        "answer2",
        "answer3",
        "answer4",
        "answer5",
        "answer6",
    },
    instruction = [=[
<h>Практика: предскажи результат or</h>
<t>Ниже даны выражения с <k>or</k>. Не нужно использовать print или сам оператор <k>or</k>.</t>
<t>Твоя задача — написать, что вернёт каждое выражение.</t>
<t>Если результат — строка, пиши её в кавычках. Если число — без кавычек. Если nil — пиши nil. Если false — пиши false.</t>
<code>
nil or "Запасной"
false or "Запасной"
"Артас" or "Странник"
0 or "Запасной"
"" or "Запасной"
nil or false
</code>
<w>Помни: в Lua только nil и false считаются ложными. Число 0, пустая строка "" и пустая таблица {} — это истина.</w>
]=],
    initialCode = [=[
answer1 = nil -- nil or "Запасной"
answer2 = nil -- false or "Запасной"
answer3 = nil -- "Артас" or "Странник"
answer4 = nil -- 0 or "Запасной"
answer5 = nil -- "" or "Запасной"
answer6 = nil -- nil or false
]=],
    requireKeywords = {
        "answer1",
        "answer2",
        "answer3",
        "answer4",
        "answer5",
        "answer6",
        "=",
    },
    forbidKeywords = {
        "or",
    },
    checkCode = function()
        return _G.answer1 == "Запасной"
            and _G.answer2 == "Запасной"
            and _G.answer3 == "Артас"
            and _G.answer4 == 0
            and _G.answer5 == ""
            and _G.answer6 == false
    end,
}

ns_llua['lua'][21.6] = {
    type = "commenttest",
    title = "Практика: тернарный оператор — прочность предмета",
    helpModules = {21.2},
    preloadVars = {
        {var = "durability", value = 0, desc = "durability = 0"},
        {var = "itemStatus", desc = "itemStatus очищается перед проверкой"},
    },
    reportVars = {"itemStatus"},
    instruction = [=[
<h>Практика: тернарный оператор — прочность предмета</h>
<t>Уже создана переменная:</t>
<code>
durability = 0
</code>
<t>Создай глобальную переменную <k>itemStatus</k> через тернарный паттерн.</t>
<t>Условие: <k>durability</k> больше <n>0</n>.</t>
<t>Если условие истинно, значение должно быть <s>"Исправно"</s>.</t>
<t>Если условие ложно, значение должно быть <s>"Сломано"</s>.</t>
<t>Используй паттерн: условие <k>and</k> значение_если_да <k>or</k> значение_если_нет.</t>
<t>Ожидаемый результат:</t>
<code>
itemStatus = "Сломано"
</code>
<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, переменная нужна глобальная.</w>
]=],
    initialCode = [=[
-- Создай itemStatus через тернарный паттерн
]=],
    requireKeywords = {
        "itemStatus",
        "durability",
        "and",
        "or",
        "0",
    },
    checkCode = function()
        return _G.itemStatus == "Сломано"
    end,
}

ns_llua['lua'][21.7] = {
    type = "commenttest",
    title = "Практика: тернарный оператор — уровень",
    helpModules = {21.2},
    preloadVars = {
        {var = "playerLevel", value = 80, desc = "playerLevel = 80"},
        {var = "maxLevel", value = 80, desc = "maxLevel = 80"},
        {var = "levelText", desc = "levelText очищается перед проверкой"},
    },
    reportVars = {"levelText"},
    instruction = [=[
<h>Практика: тернарный оператор — уровень</h>
<t>Уже созданы переменные:</t>
<code>
playerLevel = 80
maxLevel = 80
</code>
<t>Создай глобальную переменную <k>levelText</k> через тернарный паттерн.</t>
<t>Условие: <k>playerLevel</k> больше или равно <k>maxLevel</k>.</t>
<t>Если условие истинно, значение должно быть <s>"Максимум"</s>.</t>
<t>Если условие ложно, значение должно быть <s>"Расти"</s>.</t>
<t>Ожидаемый результат:</t>
<code>
levelText = "Максимум"
</code>
<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, переменная нужна глобальная.</w>
]=],
    initialCode = [=[
-- Создай levelText через тернарный паттерн
]=],
    requireKeywords = {
        "levelText",
        "playerLevel",
        "maxLevel",
        "and",
        "or",
        ">=",
    },
    checkCode = function()
        return _G.levelText == "Максимум"
    end,
}

ns_llua['lua'][21.8] = {
    type = "commenttest",
    title = "Практика: тернарный оператор — хватает ли золота",
    helpModules = {21.2, 10},
    preloadVars = {
        {var = "price", value = "250", desc = 'price = "250" (строка)'},
        {var = "gold", value = 500, desc = "gold = 500"},
        {var = "canBuy", desc = "canBuy очищается перед проверкой"},
    },
    reportVars = {"canBuy"},
    instruction = [=[
<h>Практика: тернарный оператор — хватает ли золота</h>
<t>Уже созданы переменные:</t>
<code>
price = "250"
gold = 500
</code>
<t>Цена лежит в переменной как строка. Чтобы сравнить её с золотом, нужно преобразование.</t>
<t>Создай глобальную переменную <k>canBuy</k> через тернарный паттерн.</t>
<t>Условие: <k>gold</k> больше или равно цене.</t>
<t>Если условие истинно, значение должно быть <s>"Хватает"</s>.</t>
<t>Если условие ложно, значение должно быть <s>"Не хватает"</s>.</t>
<t>Ожидаемый результат:</t>
<code>
canBuy = "Хватает"
</code>
<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, переменная нужна глобальная.</w>
]=],
    initialCode = [=[
-- Создай canBuy через tonumber и тернарный паттерн
]=],
    requireKeywords = {
        "canBuy",
        "price",
        "gold",
        "and",
        "or",
        ">=",
    },
    checkCode = function()
        return _G.canBuy == "Хватает"
    end,
}

ns_llua['lua'][22] = {
    type = "printtest",
    title = "Практика: and / or / not",
    helpModules = {21, 15},
    content = [=[
<h>Практика: and / or / not</h>
<t>Выведи результат логического выражения через <k>print</k>.</t>
<t>Задания проверяются по очереди.</t>
]=],
    tasks = {
        {
            desc = "Выведи результат 5 > 3 and 10 > 7",
            hint = "Используй /run print(5 > 3 and 10 > 7)",
            pattern = "true",
            requireKeywords = {"print", "and", "5>3", "10>7"},
            forbidKeywords = {"true", "false", "nil"},
        },
        {
            desc = "Выведи результат 5 > 3 and 10 < 7",
            hint = "Используй /run print(5 > 3 and 10 < 7)",
            pattern = "false",
            requireKeywords = {"print", "and", "5>3", "10<7"},
            forbidKeywords = {"true", "false", "nil"},
        },
        {
            desc = "Выведи результат 5 < 3 or 10 > 7",
            hint = "Используй /run print(5 < 3 or 10 > 7)",
            pattern = "true",
            requireKeywords = {"print", "or", "5<3", "10>7"},
            forbidKeywords = {"true", "false", "nil"},
        },
        {
            desc = "Выведи результат 5 < 3 or 10 < 7",
            hint = "Используй /run print(5 < 3 or 10 < 7)",
            pattern = "false",
            requireKeywords = {"print", "or", "5<3", "10<7"},
            forbidKeywords = {"true", "false", "nil"},
        },
        {
            desc = "Выведи результат not (5 < 3)",
            hint = "Используй /run print(not (5 < 3))",
            pattern = "true",
            requireKeywords = {"print", "not", "5<3"},
            forbidKeywords = {"true", "false", "nil"},
        },
        {
            desc = "Выведи результат not nil",
            hint = "Используй /run print(not nil)",
            pattern = "true",
            requireKeywords = {"print", "not", "nil"},
            forbidKeywords = {"true", "false"},
        },
    },
}

ns_llua['lua'][23] = {
    type = "commenttest",
    title = "Практика: and / or / not в условии",
    helpModules = {21, 19},
    preloadVars = {
        {var = "isAlive", value = true, desc = "isAlive = true"},
        {var = "inCombat", value = false, desc = "inCombat = false"},
        {var = "playerLevel", value = 70, desc = "playerLevel = 70"},
    },
    instruction = [=[
<h>Практика: and / or / not в условии</h>
<t>Переменные уже созданы:</t>
<code>
isAlive = true
inCombat = false
playerLevel = 70
</code>
<t>Напиши условие: если персонаж жив, не в бою и его уровень не меньше 60, выведи <s>"Готов к рейду"</s>. Иначе выведи <s>"Не готов"</s>.</t>
<t>Используй <k>and</k>, <k>not</k> и сравнение <k>>=</k>.</t>

]=],
    initialCode = [=[
-- Напиши условие здесь
]=],
    expectedOutput = "Готов к рейду",
    requireKeywords = {"isAlive", "inCombat", "playerLevel", "and", "not", ">=", "60", "if", "then", "else", "end", "print"},
}

ns_llua['lua'][24] = {
    type = "commenttest",
    title = "Комбо-тест: переменные, типы и type",
    helpModules = {4, 15},
    instruction = [=[
<h>Комбо-тест: переменные, типы и type</h>
<t>Создай глобальные переменные:</t>
<t><k>playerName</k> — любая непустая строка.</t>
<t><k>playerLevel</k> — любое число.</t>
<t><k>playerOnline</k> — любое логическое значение.</t>
<t><k>playerType</k> — строка с типом переменной <k>playerLevel</k>. Используй функцию <k>type</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {"playerName", "playerLevel", "playerOnline", "playerType", "type"},
    checkCode = function()
        return type(_G.playerName) == "string"
            and _G.playerName ~= ""
            and type(_G.playerLevel) == "number"
            and type(_G.playerOnline) == "boolean"
            and _G.playerType == "number"
    end,
}

ns_llua['lua'][25] = {
    type = "printtest",
    title = "Комбо-тест: print, математика и конкатенация",
    helpModules = {7, 10},
    content = [=[
<h>Комбо-тест: print, математика и конкатенация</h>
<t>Выполни задания по очереди через <k>/run</k>.</t>
]=],
    tasks = {
        {
            desc = "Выведи результат выражения 7 + 3 * 2",
            pattern = "13",
            requireKeywords = {"print", "7", "3", "2", "+", "*"},
            forbidKeywords = {"13"},
        },
        {
            desc = "Выведи фразу LEVEL 80, склеив три части: слово LEVEL, пробел и число 80",
            pattern = "LEVEL 80",
            requireConcat = true,
            requiredConcatCount = 2,
            requireKeywords = {"print", "LEVEL", "80", ".."},
            forbidKeywords = {"LEVEL 80"},
        },
        {
            desc = "Выведи остаток от деления 17 на 5",
            pattern = "2",
            requireKeywords = {"print", "17", "5", "%"},
        },
    },
}

ns_llua['lua'][26] = {
    type = "commenttest",
    title = "Комбо-тест: tonumber и string.format",
    helpModules = {7, 10},
    preloadVars = {
        {var = "itemName", value = "Клинок", desc = "itemName = \"Клинок\""},
        {var = "itemLevel", value = "25", desc = "itemLevel = \"25\""},
        {var = "itemCount", value = 3, desc = "itemCount = 3"},
    },
    instruction = [=[
<h>Комбо-тест: tonumber и string.format</h>
<t>Уже созданы переменные:</t>
<t><k>itemName</k> = "Клинок" (строка).</t>
<t><k>itemLevel</k> = "25" (строка).</t>
<t><k>itemCount</k> = 3 (число).</t>
<t>Создай глобальную переменную <k>itemLevelNumber</k>: преобразуй <k>itemLevel</k> в число.</t>
<t>Создай глобальную переменную <k>report</k> с помощью <k>string.format</k> по шаблону:</t>
<s>"Предмет: %s, уровень: %d, количество: %d"</s>
<t>В шаблон нужно подставить: имя предмета, числовой уровень и количество.</t>
<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {"itemName", "itemLevel", "itemCount", "itemLevelNumber", "report", "tonumber", "string.format"},
    checkCode = function()
        return type(_G.itemLevelNumber) == "number"
            and _G.itemLevelNumber == 25
            and _G.report == "Предмет: Клинок, уровень: 25, количество: 3"
    end,
}

ns_llua['lua'][27] = {
    type = "commenttest",
    title = "Комбо-тест: множественное присваивание",
    helpModules = {11, 1},
    preloadVars = {
        {var = "a", value = 5, desc = "a = 5"},
        {var = "b", value = 8, desc = "b = 8"},
        {var = "c", value = 3, desc = "c = 3"},
    },
    instruction = [=[
<h>Комбо-тест: множественное присваивание</h>
<t>Уже созданы переменные:</t>
<t><k>a</k> = 5, <k>b</k> = 8, <k>c</k> = 3.</t>
<t>Напиши одну строку множественного присваивания, чтобы значения повернулись по кругу:</t>
<t><k>a</k> должно стать 8, <k>b</k> должно стать 3, <k>c</k> должно стать 5.</t>
<t>Нельзя использовать <k>local</k>, дополнительные переменные и несколько строк.</t>
]=],
    initialCode = [=[
-- Напиши одну строку здесь
]=],
    requireKeywords = {"a", "b", "c", "=", ","},
    singleLine = true,
    checkCode = function()
        return _G.a == 8 and _G.b == 3 and _G.c == 5
    end,
}

ns_llua['lua'][28] = {
    type = "commenttest",
    title = "Комбо-тест: if, and, or, not",
    helpModules = {17, 19, 21},
    preloadVars = {
        {var = "hp", value = 60, desc = "hp = 60"},
        {var = "mana", value = 40, desc = "mana = 40"},
        {var = "inCombat", value = false, desc = "inCombat = false"},
    },
    instruction = [=[
<h>Комбо-тест: if, and, or, not</h>
<t>Уже созданы переменные:</t>
<t><k>hp</k> = 60, <k>mana</k> = 40, <k>inCombat</k> = false.</t>
<t>Создай глобальную переменную <k>status</k> с помощью условия:</t>
<t>Если <k>inCombat</k> или <k>hp</k> меньше 20, значение должно быть <s>"Бой"</s>.</t>
<t>Иначе, если <k>mana</k> больше или равно 50 и персонаж не в бою, значение должно быть <s>"Магия"</s>.</t>
<t>Иначе значение должно быть <s>"Ожидание"</s>.</t>
<t>Используй <k>if</k>, <k>elseif</k>, <k>else</k> и <k>end</k>. Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {"hp", "mana", "inCombat", "status", "if", "elseif", "else", "end", "or", "and", "not"},
    checkCode = function()
        return _G.status == "Ожидание"
    end,
}

ns_llua['lua'][29] = {
    type = "commenttest",
    title = "Комбо-тест: таблица, # и индексы",
    helpModules = {4},
    instruction = [=[
<h>Оператор # для таблиц</h>
<t>Оператор <k>#</k> можно применять к таблицам. Для таблицы-списка он возвращает количество элементов.</t>
<code>
local example = {"Меч", "Щит"}
print(#example) -- 2
</code>

<w>Важно:</w> предупреждение про <k>#</k> и кириллицу касается строк.
<t>В WoW 3.3.5 для строк <k>#</k> считает байты, а не символы. Поэтому длина строки с кириллицей может быть больше, чем количество букв.</t>
<t>Но здесь мы применяем <k>#</k> к таблице, поэтому содержимое строк не влияет на количество элементов.</t>

<h>Задание</h>
<t>Создай глобальную таблицу <k>bag</k> с четырьмя строками по порядку:</t>
<t>"Факел", "Верёвка", "Кремень", "Компас".</t>
<t>Создай глобальную переменную <k>bagCount</k> с количеством элементов в таблице. Используй оператор <k>#</k>.</t>
<t>Создай глобальную переменную <k>firstItem</k> с первым элементом таблицы.</t>
<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {"bag", "bagCount", "firstItem", "#bag", "bag[1]", "Факел", "Верёвка", "Кремень", "Компас"},
    checkCode = function()
        return type(_G.bag) == "table"
            and _G.bag[1] == "Факел"
            and _G.bag[2] == "Верёвка"
            and _G.bag[3] == "Кремень"
            and _G.bag[4] == "Компас"
            and _G.bagCount == 4
            and _G.firstItem == "Факел"
    end,
}

ns_llua['lua'][29.1] = {
    type = "info",
    title = "Изменение таблиц: table.insert, table.remove и ручное управление",
    helpModules = {4, 29},
    content = [=[
<h>Изменение таблиц</h>
<t>Таблицу можно не только создать сразу со значениями. Её можно менять: добавлять элементы, удалять их и сдвигать индексы.</t>

<h>table.insert</h>
<t>Функция <k>table.insert</k> добавляет элемент в таблицу.</t>

<t>Вариант 1: добавить в конец таблицы.</t>
<code>
local items = {"Меч"}
table.insert(items, "Щит")

print(items[1]) -- "Меч"
print(items[2]) -- "Щит"
print(#items)   -- 2
</code>

<t>Вариант 2: вставить элемент по позиции.</t>
<code>
local items = {"Меч", "Зелье"}
table.insert(items, 2, "Щит")

print(items[1]) -- "Меч"
print(items[2]) -- "Щит"
print(items[3]) -- "Зелье"
print(#items)   -- 3
</code>

<w>Важно:</w> при вставке по позиции элементы, начиная с этой позиции, сдвигаются вправо.

<h>table.remove</h>
<t>Функция <k>table.remove</k> удаляет элемент из таблицы.</t>

<t>Вариант 1: удалить последний элемент.</t>
<code>
local items = {"Меч", "Щит", "Зелье"}
table.remove(items)

print(items[1]) -- "Меч"
print(items[2]) -- "Щит"
print(items[3]) -- nil
print(#items)   -- 2
</code>

<t>Вариант 2: удалить элемент по позиции.</t>
<code>
local items = {"Меч", "Щит", "Зелье"}
table.remove(items, 2)

print(items[1]) -- "Меч"
print(items[2]) -- "Зелье"
print(#items)   -- 2
</code>

<t>Функция <k>table.remove</k> также возвращает удалённый элемент.</t>
<code>
local items = {"Меч", "Щит", "Зелье"}
local removed = table.remove(items, 2)

print(removed) -- "Щит"
print(#items)  -- 2
</code>

<h>Добавление через t[#t + 1]</h>
<t>Добавить элемент в конец таблицы можно и без <k>table.insert</k>:</t>
<code>
local items = {"Меч"}
items[#items + 1] = "Щит"

print(items[2]) -- "Щит"
print(#items)   -- 2
</code>

<t>Запись <k>t[#t + 1] = value</k> означает:</t>
<t>- взять текущую длину таблицы;</t>
<t>- прибавить 1;</t>
<t>- записать значение в следующий свободный индекс.</t>

<h>Удаление последнего элемента вручную</h>
<t>Последний элемент можно удалить, записав <k>nil</k> в последний индекс:</t>
<code>
local items = {"Меч", "Щит", "Зелье"}
items[#items] = nil

print(#items) -- 2
</code>

<w>Важно:</w> так безопасно удалять только последний элемент. Если просто записать <k>nil</k> где-нибудь в середине массива, можно получить "дырку", и оператор <k>#</k> может работать непредсказуемо.

<h>Что выбрать?</h>
<t>Для большинства задач:</t>
<t>- добавление в конец: <k>table.insert(t, value)</k> или <k>t[#t + 1] = value</k>;</t>
<t>- вставка по позиции: <k>table.insert(t, pos, value)</k>;</t>
<t>- удаление: <k>table.remove(t)</k> или <k>table.remove(t, pos)</k>.</t>

<t>Ручное управление индексами полезно для понимания, как устроена таблица, но в реальном коде чаще используют <k>table.insert</k> и <k>table.remove</k>.</t>
]=],
}

ns_llua['lua'][29.2] = {
    type = "commenttest",
    title = "Практика: вставка элементов через table.insert",
    helpModules = {29.1},
    preloadVars = {
        {var = "insertBox", desc = "insertBox очищается перед проверкой"},
    },
    reportVars = {"insertBox"},
    instruction = [=[
<h>Практика: вставка элементов через table.insert</h>
<t>Создай глобальную таблицу <k>insertBox</k>.</t>
<t>Затем добавь в неё элементы через <k>table.insert</k>.</t>

<t>Порядок действий:</t>
<t>1. Создай пустую таблицу <k>insertBox</k>.</t>
<t>2. Добавь в конец строку <s>"Меч"</s>.</t>
<t>3. Добавь в конец строку <s>"Зелье"</s>.</t>
<t>4. Вставь между ними вторым элементом строку <s>"Щит"</s>.</t>

<t>Ожидаемый результат:</t>
<code>
insertBox = {"Меч", "Щит", "Зелье"}
</code>

<w>Используй только <k>table.insert</k>. Циклы не нужны.</w>
<w>Не используй <k>local</k>, таблица нужна глобальная.</w>
]=],
    initialCode = [=[
-- Создай insertBox и добавь элементы через table.insert
]=],
    requireKeywords = {
        "table.insert",
        "insertBox",
        "2",
    },
    checkCode = function()
        return type(_G.insertBox) == "table"
            and #_G.insertBox == 3
            and _G.insertBox[1] == "Меч"
            and _G.insertBox[2] == "Щит"
            and _G.insertBox[3] == "Зелье"
    end,
}

ns_llua['lua'][29.3] = {
    type = "commenttest",
    title = "Практика: удаление элементов через table.remove",
    helpModules = {29.1},
    preloadVars = {
        {var = "removeBox", desc = "removeBox очищается перед проверкой"},
        {var = "removedItem", desc = "removedItem очищается перед проверкой"},
    },
    reportVars = {"removeBox", "removedItem"},
    instruction = [=[
<h>Практика: удаление элементов через table.remove</h>
<t>Создай глобальную таблицу <k>removeBox</k> с четырьмя строками:</t>
<s>"Меч", "Щит", "Зелье", "Факел"</s>

<t>Затем выполни удаления через <k>table.remove</k>:</t>
<t>1. Удали последний элемент.</t>
<t>2. Удали элемент с индексом 2.</t>
<t>3. Удали элемент с индексом 1 и сохрани результат в глобальную переменную <k>removedItem</k>.</t>

<t>Ожидаемый результат:</t>
<code>
removeBox = {"Зелье"}
removedItem = "Меч"
</code>

<w>Используй только <k>table.remove</k>. Циклы не нужны.</w>
<w>Не используй <k>local</k>, переменные нужны глобальные.</w>
]=],
    initialCode = [=[
-- Создай removeBox и выполни удаления через table.remove
]=],
    requireKeywords = {
        "table.remove",
        "removeBox",
        "removedItem",
        "2",
        "1",
    },
    checkCode = function()
        return type(_G.removeBox) == "table"
            and #_G.removeBox == 1
            and _G.removeBox[1] == "Зелье"
            and _G.removedItem == "Меч"
    end,
}

ns_llua['lua'][29.4] = {
    type = "commenttest",
    title = "Практика: ручное добавление элементов через t[#t + 1]",
    helpModules = {29.1},
    preloadVars = {
        {var = "manualBox", desc = "manualBox очищается перед проверкой"},
    },
    reportVars = {"manualBox"},
    instruction = [=[
<h>Практика: ручное добавление элементов</h>
<t>В этом задании нельзя использовать <k>table.insert</k> и <k>table.remove</k>.</t>
<t>Будем управлять таблицей вручную через индексы.</t>

<t>Создай глобальную таблицу <k>manualBox</k>.</t>

<t>Порядок действий:</t>
<t>1. Добавь в конец строку <s>"Меч"</s> через <k>manualBox[#manualBox + 1]</k>.</t>
<t>2. Добавь в конец строку <s>"Зелье"</s> тем же способом.</t>
<t>3. Вставь вторым элементом строку <s>"Щит"</s> вручную.</t>
<t>4. Добавь в конец строку <s>"Факел"</s> через <k>manualBox[#manualBox + 1]</k>.</t>

<h>Подсказка по ручной вставке</h>
<t>Чтобы вставить элемент в позицию 2, сначала сдвинь текущий второй элемент в третий индекс:</t>
<code>
manualBox[3] = manualBox[2]
manualBox[2] = "Щит"
</code>

<t>Ожидаемый результат:</t>
<code>
manualBox = {"Меч", "Щит", "Зелье", "Факел"}
</code>

<w>Не используй <k>local</k>, таблица нужна глобальная.</w>
<w>Циклы не нужны.</w>
]=],
    initialCode = [=[
-- Создай manualBox и заполни её вручную
]=],
    requireKeywords = {
        "manualBox",
        "#manualBox",
        "manualBox[3]",
        "manualBox[2]",
    },
    forbidKeywords = {
        "table.insert",
        "table.remove",
    },
    checkCode = function()
        return type(_G.manualBox) == "table"
            and #_G.manualBox == 4
            and _G.manualBox[1] == "Меч"
            and _G.manualBox[2] == "Щит"
            and _G.manualBox[3] == "Зелье"
            and _G.manualBox[4] == "Факел"
    end,
}

ns_llua['lua'][29.5] = {
    type = "commenttest",
    title = "Практика: ручное удаление элементов",
    helpModules = {29.1},
    preloadVars = {
        {var = "manualRemove", desc = "manualRemove очищается перед проверкой"},
    },
    reportVars = {"manualRemove"},
    instruction = [=[
<h>Практика: ручное удаление элементов</h>
<t>Создай глобальную таблицу <k>manualRemove</k> с четырьмя строками по порядку:</t>
<s>"Меч", "Щит", "Зелье", "Факел"</s>

<t>Затем вручную удали из неё два элемента:</t>
<t>1. Последний элемент.</t>
<t>2. Второй элемент. Для этого сначала сдвинь третий элемент на место второго, затем убери лишний последний элемент.</t>

<t>Ожидаемый результат:</t>
<code>
manualRemove = {"Меч", "Зелье"}
</code>

<w>Нельзя использовать <k>table.remove</k>, <k>table.insert</k>, <k>local</k> и циклы.</w>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {
        "manualRemove",
        "#manualRemove",
        "nil",
        "manualRemove[2]",
        "manualRemove[3]",
    },
    forbidKeywords = {
        "table.remove",
        "table.insert",
    },
    checkCode = function()
        return type(_G.manualRemove) == "table"
            and #_G.manualRemove == 2
            and _G.manualRemove[1] == "Меч"
            and _G.manualRemove[2] == "Зелье"
    end,
}

ns_llua['lua'][30] = {
    type = "commenttest",
    title = "Итоговый комбо-тест",
    helpModules = {7, 10, 17, 19, 21},
    preloadVars = {
        {var = "playerLevel", value = 75, desc = "playerLevel = 75"},
        {var = "maxLevel", value = 80, desc = "maxLevel = 80"},
        {var = "isAlive", value = true, desc = "isAlive = true"},
        {var = "gold", value = "1500", desc = "gold = \"1500\""},
    },
    instruction = [=[
<h>Итоговый комбо-тест</h>
<t>Уже созданы переменные:</t>
<t><k>playerLevel</k> = 75, <k>maxLevel</k> = 80, <k>isAlive</k> = true, <k>gold</k> = "1500".</t>
<t>Создай глобальную переменную <k>goldNumber</k>: преобразуй <k>gold</k> в число.</t>
<t>Создай глобальную переменную <k>levelText</k> с помощью условия:</t>
<t>Если <k>playerLevel</k> больше или равно <k>maxLevel</k>, значение должно быть <s>"Максимум"</s>, иначе <s>"Расти"</s>.</t>
<t>Создай глобальную переменную <k>canTrade</k> с помощью условия:</t>
<t>Если <k>isAlive</k> и <k>goldNumber</k> больше или равно 1000, значение должно быть <k>true</k>, иначе <k>false</k>.</t>
<t>Создай глобальную переменную <k>summary</k> с помощью <k>string.format</k> по шаблону:</t>
<s>"Уровень: %d, Золото: %d"</s>
<t>В шаблон нужно подставить <k>playerLevel</k> и <k>goldNumber</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {"playerLevel", "maxLevel", "isAlive", "gold", "goldNumber", "levelText", "canTrade", "summary", "tonumber", "if", "then", "else", "end", "and", "string.format"},
    checkCode = function()
        return type(_G.goldNumber) == "number"
            and _G.goldNumber == 1500
            and _G.levelText == "Расти"
            and _G.canTrade == true
            and _G.summary == "Уровень: 75, Золото: 1500"
    end,
}

ns_llua['lua'][31] = {
    type = "info",
    title = "Циклы: for",
    helpModules = {4, 7},
    content = [=[
<h>Цикл for</h>
<t>Цикл <k>for</k> нужен, чтобы повторять код нужное количество раз.</t>
<t>Он сам меняет переменную цикла и сам останавливается, когда диапазон закончится.</t>

<h>Числовой for</h>
<code>
for i = 1, 5 do -- начинаем цикл: переменная i будет принимать значения 1, 2, 3, 4, 5
    print(i) -- выводим текущее значение i в чат
end -- закрываем цикл
</code>

<h>Обратный отсчёт</h>
<t>Третье число в <k>for</k> — это шаг. Если шаг отрицательный, цикл идёт назад.</t>
<code>
for i = 5, 1, -1 do -- i меняется от 5 до 1 с шагом -1
    print(i) -- выводим 5, 4, 3, 2, 1
end -- закрываем цикл
</code>

<h>Накопление суммы</h>
<t>Часто внутри цикла накапливают результат в отдельной переменной.</t>
<code>
local sum = 0 -- создаём переменную для накопления суммы
for i = 1, 5 do -- проходим числа от 1 до 5
    sum = sum + i -- прибавляем текущее значение i к сумме
end -- завершаем цикл
print(sum) -- выводим итоговую сумму: 15
</code>

<h>Накопление строки</h>
<t>Точно так же можно собирать строку через конкатенацию.</t>
<code>
local text = "" -- создаём пустую строку для результата
for i = 1, 3 do -- проходим числа от 1 до 3
    text = text .. i .. " " -- приклеиваем число и пробел к строке
end -- завершаем цикл
print(text) -- выводим "1 2 3 "
</code>

<h>Перебор таблицы через ipairs</h>
<t>Если у тебя таблица-список, её удобно перебирать через <k>ipairs</k>.</t>
<code>
local items = {"Меч", "Щит"} -- создаём таблицу-список из двух предметов
for index, value in ipairs(items) do -- перебираем элементы по порядку
    print(index) -- выводим номер элемента: сначала 1, потом 2
    print(value) -- выводим значение: сначала "Меч", потом "Щит"
end -- завершаем цикл
</code>

<h>Важно для практики</h>
<t>В практических модулях курса проверяются глобальные переменные.</t>
<t>Поэтому нужные переменные создавай без <k>local</k>, если задание просит сохранить результат для проверки.</t>
]=],
}

ns_llua['lua'][31.1] = {
    type = "commenttest",
    title = "Практика: table.insert и цикл for",
    helpModules = {31, 29.1},
    preloadVars = {
        {var = "loopNumbers", desc = "loopNumbers очищается перед проверкой"},
    },
    reportVars = {"loopNumbers"},
    instruction = [=[
<h>Практика: table.insert и цикл for</h>
<t>Создай глобальную таблицу <k>loopNumbers</k>.</t>
<t>Заполни её числами от 1 до 5 с помощью цикла <k>for</k> и функции <k>table.insert</k>.</t>

<t>Ожидаемый результат:</t>
<code>
loopNumbers = {1, 2, 3, 4, 5}
</code>

<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, таблица нужна глобальная.</w>
]=],
    initialCode = [=[
-- Создай loopNumbers и заполни её через for и table.insert
]=],
    requireKeywords = {
        "loopNumbers",
        "for",
        "do",
        "end",
        "table.insert",
        "1",
        "5",
    },
    checkCode = function()
        if type(_G.loopNumbers) ~= "table" then
            return false
        end

        if #_G.loopNumbers ~= 5 then
            return false
        end

        for i = 1, 5 do
            if _G.loopNumbers[i] ~= i then
                return false
            end
        end

        return true
    end,
}

ns_llua['lua'][31.2] = {
    type = "commenttest",
    title = "table.concat: склейка таблицы в строку",
    helpModules = {31, 29.1, 7},
    preloadVars = {
        {var = "concatWords", desc = "concatWords очищается перед проверкой"},
        {var = "concatSpace", desc = "concatSpace очищается перед проверкой"},
        {var = "concatComma", desc = "concatComma очищается перед проверкой"},
    },
    reportVars = {"concatWords", "concatSpace", "concatComma"},
    instruction = [=[
<h>table.concat</h>
<t>Функция <k>table.concat</k> склеивает элементы таблицы в одну строку.</t>
<t>Первым аргументом передаётся таблица, вторым — разделитель.</t>

<code>
local words = {"Меч", "Щит", "Зелье"}
print(table.concat(words, " "))  -- "Меч Щит Зелье"
print(table.concat(words, ", ")) -- "Меч, Щит, Зелье"
</code>

<t>Это удобнее, чем вручную собирать строку через конкатенацию в цикле.</t>

<h>Практика</h>
<t>Создай глобальную таблицу <k>concatWords</k> с тремя строками:</t>
<s>"Меч", "Щит", "Зелье"</s>

<t>Создай глобальную переменную <k>concatSpace</k>:</t>
<t>Используй <k>table.concat</k> с разделителем <s>" "</s> (пробел).</t>

<t>Создай глобальную переменную <k>concatComma</k>:</t>
<t>Используй <k>table.concat</k> с разделителем <s>", "</s> (запятая и пробел).</t>

<t>Ожидаемый результат:</t>
<code>
concatSpace = "Меч Щит Зелье"
concatComma = "Меч, Щит, Зелье"
</code>

<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, переменные нужны глобальные.</w>
]=],
    initialCode = [=[
-- Создай concatWords, concatSpace и concatComma
]=],
    requireKeywords = {
        "concatWords",
        "concatSpace",
        "concatComma",
        "table.concat",
    },
    checkCode = function()
        return type(_G.concatWords) == "table"
            and #_G.concatWords == 3
            and _G.concatWords[1] == "Меч"
            and _G.concatWords[2] == "Щит"
            and _G.concatWords[3] == "Зелье"
            and _G.concatSpace == "Меч Щит Зелье"
            and _G.concatComma == "Меч, Щит, Зелье"
    end,
}

ns_llua['lua'][32] = {
    type = "info",
    title = "Циклы: while",
    helpModules = {31},
    content = [=[
<h>Цикл while</h>
<t>Цикл <k>while</k> повторяет код, пока условие истинно.</t>
<t>В отличие от числового <k>for</k>, здесь ты сам следишь за тем, когда цикл должен остановиться.</t>

<h>Обычный while</h>
<code>
local count = 0 -- создаём переменную-счётчик
while count < 3 do -- повторяем цикл, пока count меньше 3
    print(count) -- выводим текущее значение счётчика
    count = count + 1 -- увеличиваем счётчик на 1
end -- закрываем цикл
</code>

<h>Бесконечный цикл</h>
<t>Если условие всегда истинно, цикл будет выполняться бесконечно.</t>
<code>
while true do -- условие всегда равно true
    print("Это будет повторяться бесконечно") -- выводим сообщение каждый раз
end -- цикл не останавливается сам
</code>
<w>Опасность:</w> такой цикл может зависнуть, если внутри нет выхода через <k>break</k> или другого способа остановки.

<h>Бесконечный цикл с break</h>
<t>Иногда цикл делают бесконечным, но останавливают вручную через <k>break</k>.</t>
<code>
local count = 0 -- создаём переменную-счётчик
while true do -- начинаем бесконечный цикл
    count = count + 1 -- увеличиваем счётчик на 1
    if count >= 3 then -- проверяем, пора ли остановиться
        break -- выходим из цикла
    end -- закрываем условие if
end -- закрываем цикл while
print(count) -- выводим 3
</code>

<h>Частая ошибка</h>
<t>Если забыть изменить счётчик, цикл станет бесконечным.</t>
<code>
local count = 0 -- создаём переменную-счётчик
while count < 3 do -- условие изначально истинно
    print(count) -- выводим count
    -- здесь забыли count = count + 1, поэтому цикл никогда не закончится
end -- закрываем цикл
</code>
]=],
}

ns_llua['lua'][33] = {
    type = "info",
    title = "Поиск подстроки: string.find",
    helpModules = {31, 32},
    content = [=[
<h>string.find</h>
<t>Функция <k>string.find</k> ищет часть строки внутри другой строки.</t>
<t>Если подстрока найдена, функция возвращает позицию.</t>
<t>Если подстрока не найдена, функция возвращает <k>nil</k>.</t>

<h>Простой пример</h>
<code>
local pos = string.find("molot", "ol") -- ищем "ol" внутри слова "molot"
print(pos) -- выводим 2, потому что совпадение начинается со второго символа
local notFound = string.find("shield", "ol") -- ищем "ol" внутри слова "shield"
print(notFound) -- выводим nil, потому что совпадения нет
</code>

<h>string.find в условии</h>
<t>Так как найденная позиция считается истиной, а <k>nil</k> — ложью, <k>string.find</k> удобно использовать в <k>if</k>.</t>
<code>
if string.find("kolco", "ol") then -- если внутри "kolco" есть "ol", условие истинно
    print("Найдено") -- этот код выполнится
end -- закрываем условие
</code>

<h>Поиск по таблице слов</h>
<t>Можно пройтись циклом по таблице и проверить каждое слово.</t>
<code>
local items = {"Меч", "Молот", "Щит"} -- создаём таблицу со словами
local found = "" -- создаём пустую строку для найденных слов
for _, v in ipairs(items) do -- перебираем каждое слово из таблицы
    if string.find(v, "ол") then -- если внутри текущего слова есть "ол"
        found = found .. v .. " " -- добавляем слово в результат
    end -- закрываем условие
end -- закрываем цикл
print(found) -- выводим "Молот "
</code>

<h>Важно про кириллицу</h>
<t>В WoW 3.3.5 позиции в строке считаются в байтах, а не в символах.</t>
<t>Поэтому для кириллицы номер позиции может быть больше, чем номер буквы.</t>
<t>Но для проверки «найдено / не найдено» это не мешает: главное, что возвращается число или <k>nil</k>.</t>
]=],
}

ns_llua['lua'][34] = {
    type = "commenttest",
    title = "Практика: for и сборка строки",
    helpModules = {31, 7},
    preloadVars = {
        {var = "numberSequence", desc = "numberSequence очищается перед проверкой"},
    },
    instruction = [=[
<h>Практика: for и сборка строки</h>
<t>Создай глобальную переменную <k>numberSequence</k>.</t>
<t>Собери в неё числа от 10 до 15 через пробел.</t>
<t>В конце строки тоже должен быть пробел.</t>

<t>Ожидаемое значение:</t>
<s>"10 11 12 13 14 15 "</s>

<t>Используй:</t>
<t>- цикл <k>for</k>;</t>
<t>- конкатенацию;</t>
<t>- накопление результата в переменную <k>numberSequence</k>.</t>

<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {
        "numberSequence",
        "for",
        "do",
        "end",
        "10",
        "15",
        "numberSequence=numberSequence..",
    },
    checkCode = function()
        return type(_G.numberSequence) == "string"
            and _G.numberSequence == "10 11 12 13 14 15 "
    end,
}

ns_llua['lua'][35] = {
    type = "commenttest",
    title = "Практика: for, условие и сумма",
    helpModules = {31, 10, 17},
    preloadVars = {
        {var = "totalSum", desc = "totalSum очищается перед проверкой"},
    },
    instruction = [=[
<h>Практика: for, условие и сумма</h>
<t>Создай глобальную переменную <k>totalSum</k>.</t>
<t>Посчитай сумму чисел от 1 до 10, которые больше 5.</t>

<t>То есть нужно сложить:</t>
<s>6 + 7 + 8 + 9 + 10</s>

<t>Ожидаемое значение:</t>
<s>40</s>

<t>Используй:</t>
<t>- цикл <k>for</k>;</t>
<t>- условие <k>if</k>;</t>
<t>- прибавление к <k>totalSum</k>.</t>

<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {
        "totalSum",
        "for",
        "do",
        "end",
        "if",
        "then",
        ">",
        "5",
        "totalSum=totalSum+",
    },
    checkCode = function()
        return type(_G.totalSum) == "number"
            and _G.totalSum == 40
    end,
}

ns_llua['lua'][36] = {
    type = "commenttest",
    title = "Практика: for и string.format",
    helpModules = {31, 7, 14},
    preloadVars = {
        {var = "levelReport", desc = "levelReport очищается перед проверкой"},
    },
    instruction = [=[
<h>Практика: for и string.format</h>
<t>Создай глобальную переменную <k>levelReport</k>.</t>
<t>Собери строку для уровней 1, 2 и 3.</t>

<t>Для каждого уровня нужно добавить фрагмент:</t>
<s>"Уровень: %d "</s>

<t>Ожидаемое значение:</t>
<s>"Уровень: 1 Уровень: 2 Уровень: 3 "</s>

<t>Используй:</t>
<t>- цикл <k>for</k> от 1 до 3;</t>
<t>- <k>string.format</k>;</t>
<t>- конкатенацию в переменную <k>levelReport</k>.</t>

<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {
        "levelReport",
        "for",
        "do",
        "end",
        "string.format",
        "%d",
        "Уровень:",
        "levelReport=levelReport..",
    },
    checkCode = function()
        return type(_G.levelReport) == "string"
            and _G.levelReport == "Уровень: 1 Уровень: 2 Уровень: 3 "
    end,
}

ns_llua['lua'][37] = {
    type = "commenttest",
    title = "Практика: while и счётчик",
    helpModules = {32, 7},
    preloadVars = {
        {var = "whileResult", desc = "whileResult очищается перед проверкой"},
    },
    instruction = [=[
<h>Практика: while и счётчик</h>
<t>Создай глобальную переменную <k>whileResult</k>.</t>
<t>Собери в неё числа от 0 до 4 через пробел.</t>
<t>В конце строки тоже должен быть пробел.</t>

<t>Ожидаемое значение:</t>
<s>"0 1 2 3 4 "</s>

<t>Используй:</t>
<t>- цикл <k>while</k>;</t>
<t>- переменную-счётчик <k>count</k>;</t>
<t>- условие <k>count < 5</k>;</t>
<t>- увеличение счётчика на 1;</t>
<t>- конкатенацию в переменную <k>whileResult</k>.</t>

<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {
        "whileResult",
        "while",
        "do",
        "end",
        "count",
        "<",
        "5",
        "whileResult=whileResult..",
        "count=count+1",
    },
    checkCode = function()
        return type(_G.whileResult) == "string"
            and _G.whileResult == "0 1 2 3 4 "
    end,
}

ns_llua['lua'][38] = {
    type = "commenttest",
    title = "Практика: while, break и остаток от деления",
    helpModules = {32, 10},
    preloadVars = {
        {var = "foundMultiple", desc = "foundMultiple очищается перед проверкой"},
    },
    instruction = [=[
<h>Практика: while, break и остаток от деления</h>
<t>Создай глобальную переменную <k>foundMultiple</k>.</t>
<t>Найди первое число от 1 до 30, которое делится на 7 без остатка.</t>

<w>Важно:</w>
<t>Переменная <k>foundMultiple</k> должна содержать само найденное число, а не остаток от деления.</t>

<t>Ожидаемое значение:</t>
<s>7</s>

<t>Используй:</t>
<t>- цикл <k>while</k>;</t>
<t>- переменную <k>i</k>;</t>
<t>- остаток от деления <k>%</k>;</t>
<t>- условие;</t>
<t>- выход через <k>break</k>;</t>
<t>- увеличение <k>i</k> на 1.</t>

<h>Подсказка</h>
<t>Остаток от деления вычисляется оператором <k>%</k>.</t>
<t>Если <k>i % 7</k> равно <n>0</n>, значит число <k>i</k> делится на 7 без остатка.</t>

<code>
print(14 % 7) -- 0: остатка нет, число делится без остатка
print(15 % 7) -- 1: остаток есть, число не делится без остатка
</code>

<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {
        "foundMultiple",
        "while",
        "do",
        "end",
        "if",
        "then",
        "%",
        "7",
        "break",
        "i%7==0",
        "foundMultiple=i",
        "i=i+1",
    },
    checkCode = function()
        return type(_G.foundMultiple) == "number"
            and _G.foundMultiple == 7
    end,
}

ns_llua['lua'][39] = {
    type = "commenttest",
    title = "Практика: ipairs и подсчёт с условием",
    helpModules = {31, 4, 17},
    preloadVars = {
        {var = "loot", desc = "loot очищается перед проверкой"},
        {var = "lootCount", desc = "lootCount очищается перед проверкой"},
    },
    instruction = [=[
<h>Практика: ipairs и подсчёт с условием</h>
<t>Создай глобальную таблицу <k>loot</k> с четырьмя строками по порядку:</t>
<t>"Меч", "Щит", "Зелье", "Свиток".</t>

<t>Создай глобальную переменную <k>lootCount</k>.</t>
<t>Посчитай количество предметов, которые НЕ равны "Щит".</t>

<t>Ожидаемое значение:</t>
<s>3</s>

<t>Используй:</t>
<t>- цикл <k>for</k>;</t>
<t>- <k>ipairs</k>;</t>
<t>- условие <k>if</k>;</t>
<t>- сравнение <k>~=</k>;</t>
<t>- увеличение <k>lootCount</k> на 1.</t>

<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {
        "loot",
        "lootCount",
        "for",
        "ipairs",
        "do",
        "end",
        "if",
        "then",
        "~=",
        "Щит",
        "lootCount=lootCount+1",
        "Меч",
        "Зелье",
        "Свиток",
    },
    checkCode = function()
        return type(_G.loot) == "table"
            and _G.loot[1] == "Меч"
            and _G.loot[2] == "Щит"
            and _G.loot[3] == "Зелье"
            and _G.loot[4] == "Свиток"
            and _G.lootCount == 3
    end,
}

ns_llua['lua'][40] = {
    type = "commenttest",
    title = "Практика: поиск в таблице и break",
    helpModules = {31, 4, 17},
    preloadVars = {
        {var = "pouch", desc = "pouch очищается перед проверкой"},
        {var = "elixirIndex", desc = "elixirIndex очищается перед проверкой"},
    },
    instruction = [=[
<h>Практика: поиск в таблице и break</h>
<t>Создай глобальную таблицу <k>pouch</k> с четырьмя строками по порядку:</t>
<t>"Кинжал", "Эликсир", "Свиток", "Эликсир".</t>

<t>Создай глобальную переменную <k>elixirIndex</k>.</t>
<t>Найди индекс первого элемента "Эликсир" и сохрани его в <k>elixirIndex</k>.</t>

<t>Ожидаемое значение:</t>
<s>2</s>

<t>Используй:</t>
<t>- цикл <k>for</k>;</t>
<t>- <k>ipairs</k>;</t>
<t>- переменные <k>i</k> и <k>v</k>;</t>
<t>- условие <k>if</k>;</t>
<t>- выход из цикла через <k>break</k>.</t>

<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {
        "pouch",
        "elixirIndex",
        "for",
        "ipairs",
        "do",
        "end",
        "if",
        "then",
        "break",
        "Эликсир",
        "elixirIndex=i",
    },
    checkCode = function()
        return type(_G.pouch) == "table"
            and _G.pouch[1] == "Кинжал"
            and _G.pouch[2] == "Эликсир"
            and _G.pouch[3] == "Свиток"
            and _G.pouch[4] == "Эликсир"
            and _G.elixirIndex == 2
    end,
}

ns_llua['lua'][41] = {
    type = "commenttest",
    title = "Практика: обратный отсчёт",
    helpModules = {31, 7},
    preloadVars = {
        {var = "launchSequence", desc = "launchSequence очищается перед проверкой"},
    },
    instruction = [=[
<h>Практика: обратный отсчёт</h>
<t>Создай глобальную переменную <k>launchSequence</k>.</t>
<t>Собери строку обратного отсчёта от 5 до 1.</t>
<t>После цикла добавь в конец слово "СТАРТ!".</t>

<t>Ожидаемое значение:</t>
<s>"5... 4... 3... 2... 1... СТАРТ!"</s>

<t>Используй:</t>
<t>- цикл <k>for</k> от 5 до 1;</t>
<t>- шаг <k>-1</k>;</t>
<t>- конкатенацию;</t>
<t>- добавление финального слова после цикла.</t>

<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {
        "launchSequence",
        "for",
        "do",
        "end",
        "5",
        "1",
        "-1",
        "launchSequence=launchSequence..",
        "СТАРТ!",
    },
    checkCode = function()
        return type(_G.launchSequence) == "string"
            and _G.launchSequence == "5... 4... 3... 2... 1... СТАРТ!"
    end,
}

ns_llua['lua'][41.1] = {
    type = "commenttest",
    title = "Практика: фильтрация таблицы через string.find и table.insert",
    helpModules = {31, 33, 29.1},
    preloadVars = {
        {var = "filterItems", desc = "filterItems очищается перед проверкой"},
        {var = "filteredItems", desc = "filteredItems очищается перед проверкой"},
        {var = "filteredCount", desc = "filteredCount очищается перед проверкой"},
    },
    reportVars = {"filterItems", "filteredItems", "filteredCount"},
    instruction = [=[
<h>Практика: фильтрация таблицы</h>
<t>Создай глобальную таблицу <k>filterItems</k> с пятью строками по порядку:</t>
<s>"Меч", "Молот", "Кольцо", "Щит", "Плащ"</s>

<t>Создай пустую глобальную таблицу <k>filteredItems</k>.</t>

<t>Пройди по <k>filterItems</k> циклом <k>for</k> с <k>ipairs</k>.</t>
<t>Если строка содержит подстроку <s>"ол"</s>, добавь её в <k>filteredItems</k> через <k>table.insert</k>.</t>

<t>После цикла создай глобальную переменную <k>filteredCount</k> с количеством элементов в <k>filteredItems</k>.</t>

<t>Ожидаемый результат:</t>
<code>
filteredItems = {"Молот", "Кольцо"}
filteredCount = 2
</code>

<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, переменные нужны глобальные.</w>
]=],
    initialCode = [=[
-- Создай filterItems, filteredItems и filteredCount
]=],
    requireKeywords = {
        "filterItems",
        "filteredItems",
        "filteredCount",
        "for",
        "ipairs",
        "do",
        "end",
        "string.find",
        "table.insert",
    },
    checkCode = function()
        return type(_G.filterItems) == "table"
            and #_G.filterItems == 5
            and _G.filterItems[1] == "Меч"
            and _G.filterItems[2] == "Молот"
            and _G.filterItems[3] == "Кольцо"
            and _G.filterItems[4] == "Щит"
            and _G.filterItems[5] == "Плащ"
            and type(_G.filteredItems) == "table"
            and #_G.filteredItems == 2
            and _G.filteredItems[1] == "Молот"
            and _G.filteredItems[2] == "Кольцо"
            and _G.filteredCount == 2
    end,
}

ns_llua['lua'][41.2] = {
    type = "commenttest",
    title = "Практика: безопасное удаление элементов при переборе",
    helpModules = {31, 32, 29.1, 40},
    preloadVars = {
        {var = "safeLoot", desc = "safeLoot очищается перед проверкой"},
        {var = "removedCount", desc = "removedCount очищается перед проверкой"},
    },
    reportVars = {"safeLoot", "removedCount"},
    instruction = [=[
<h>Практика: безопасное удаление элементов</h>
<t>Создай глобальную таблицу <k>safeLoot</k> с пятью строками по порядку:</t>
<s>"Меч", "Щит", "Зелье", "Щит", "Свиток"</s>

<t>Создай глобальную переменную <k>removedCount</k> и присвой ей 0.</t>

<t>Удали из <k>safeLoot</k> все элементы <s>"Щит"</s> и посчитай количество удалений в <k>removedCount</k>.</t>

<h>Почему обычный перебор может быть опасным?</h>
<t>Когда ты удаляешь элемент из таблицы, все элементы после него сдвигаются влево.</t>
<t>Если в этот момент идти по таблице обычным циклом вперёд, можно пропустить элемент, который встал на место удалённого.</t>

<h>Безопасная идея</h>
<t>Чтобы не пропускать элементы, удалять их нужно при проходе с конца таблицы к началу.</t>
<t>То есть нужно начать с последнего индекса, затем уменьшать индекс на 1 и остановиться на 1.</t>
<t>При таком проходе удаление элемента не ломает индексы тех элементов, которые ещё не обработаны.</t>

<h>Что нужно сделать</h>
<t>1. Пройди по таблице <k>safeLoot</k> с конца к началу.</t>
<t>2. На каждом шаге проверяй, равен ли текущий элемент строке <s>"Щит"</s>.</t>
<t>3. Если равен — удали этот элемент из таблицы.</t>
<t>4. После удаления увеличь <k>removedCount</k> на 1.</t>

<t>Ожидаемый результат:</t>
<code>
safeLoot = {"Меч", "Зелье", "Свиток"}
removedCount = 2
</code>

<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, переменные нужны глобальные.</w>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {
        "safeLoot",
        "removedCount",
        "for",
        "#safeLoot",
        "-1",
        "do",
        "end",
        "if",
        "table.remove",
    },
    checkCode = function()
        return type(_G.safeLoot) == "table"
            and #_G.safeLoot == 3
            and _G.safeLoot[1] == "Меч"
            and _G.safeLoot[2] == "Зелье"
            and _G.safeLoot[3] == "Свиток"
            and _G.removedCount == 2
    end,
}

ns_llua['lua'][42] = {
    type = "commenttest",
    title = "Практика: поиск по подстроке через string.find",
    helpModules = {31, 33, 4, 7},
    preloadVars = {
        {var = "items", desc = "items очищается перед проверкой"},
        {var = "found", desc = "found очищается перед проверкой"},
    },
    instruction = [=[
<h>Практика: поиск по подстроке через string.find</h>
<t>Создай глобальную таблицу <k>items</k> с пятью строками по порядку:</t>
<t>"Меч", "Молот", "Кольцо", "Щит", "Плащ".</t>

<t>Создай глобальную переменную <k>found</k>.</t>
<t>Найди все предметы, в которых есть подстрока "ол".</t>
<t>Собери их названия в строку через пробел.</t>
<t>В конце строки тоже должен быть пробел.</t>

<t>Ожидаемое значение:</t>
<s>"Молот Кольцо "</s>

<t>Используй:</t>
<t>- цикл <k>for</k>;</t>
<t>- <k>ipairs</k>;</t>
<t>- <k>string.find</k>;</t>
<t>- условие <k>if</k>;</t>
<t>- конкатенацию.</t>

<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {
        "items",
        "found",
        "for",
        "ipairs",
        "do",
        "end",
        "string.find",
        "if",
        "then",
        "ол",
        "found=found..",
        "Меч",
        "Молот",
        "Кольцо",
        "Щит",
        "Плащ",
    },
    checkCode = function()
        return type(_G.items) == "table"
            and _G.items[1] == "Меч"
            and _G.items[2] == "Молот"
            and _G.items[3] == "Кольцо"
            and _G.items[4] == "Щит"
            and _G.items[5] == "Плащ"
            and _G.found == "Молот Кольцо "
    end,
}

ns_llua['lua'][43] = {
    type = "commenttest",
    title = "Итоговый комбо-тест: циклы, tonumber, if и string.format",
    helpModules = {31, 4, 7, 10, 17},
    preloadVars = {
        {var = "goldStrings", desc = "goldStrings очищается перед проверкой"},
        {var = "bigGoldCount", desc = "bigGoldCount очищается перед проверкой"},
        {var = "bigGoldSum", desc = "bigGoldSum очищается перед проверкой"},
        {var = "bigGoldReport", desc = "bigGoldReport очищается перед проверкой"},
    },
    instruction = [=[
<h>Итоговый комбо-тест</h>
<t>Создай глобальную таблицу <k>goldStrings</k> с тремя строками:</t>
<t>"1200", "850", "2000".</t>

<t>Создай глобальные переменные:</t>
<t><k>bigGoldCount</k> — количество сумм, которые больше или равны 1000;</t>
<t><k>bigGoldSum</k> — сумма таких значений;</t>
<t><k>bigGoldReport</k> — итоговый отчёт.</t>

<t>Пройди по таблице <k>goldStrings</k> циклом <k>ipairs</k>.</t>
<t>Каждую строку преобразуй в число через <k>tonumber</k>.</t>
<t>Если число больше или равно 1000, увеличь <k>bigGoldCount</k> на 1 и прибавь число к <k>bigGoldSum</k>.</t>

<t>После цикла создай <k>bigGoldReport</k> через <k>string.format</k> по шаблону:</t>
<s>"Крупных сумм: %d, всего: %d"</s>

<t>Ожидаемые значения:</t>
<s>bigGoldCount = 2</s>
<s>bigGoldSum = 3200</s>
<s>bigGoldReport = "Крупных сумм: 2, всего: 3200"</s>

<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Напиши код здесь
]=],
    requireKeywords = {
        "goldStrings",
        "bigGoldCount",
        "bigGoldSum",
        "bigGoldReport",
        "for",
        "ipairs",
        "do",
        "end",
        "tonumber",
        "if",
        "then",
        ">=",
        "1000",
        "string.format",
        "bigGoldCount=bigGoldCount+1",
        "bigGoldSum=bigGoldSum+",
        '"1200"',
        '"850"',
        '"2000"',
    },
    checkCode = function()
        return type(_G.goldStrings) == "table"
            and _G.goldStrings[1] == "1200"
            and _G.goldStrings[2] == "850"
            and _G.goldStrings[3] == "2000"
            and _G.bigGoldCount == 2
            and _G.bigGoldSum == 3200
            and _G.bigGoldReport == "Крупных сумм: 2, всего: 3200"
    end,
}

ns_llua['lua'][44] = {
    type = "info",
    title = "Хэш-таблицы и массивы",
    helpModules = {4},
    content = [=[
<h>Хэш-таблицы и массивы</h>
<t>В Lua таблица может работать и как массив, и как словарь.</t>
<t>Это не два разных типа данных. Это одна и та же <k>table</k>, которую используют по-разному.</t>

<h>Массив</h>
<t>Массив — это таблица с числовыми ключами подряд: 1, 2, 3 и так далее.</t>
<code>
local items = {"Меч", "Щит", "Зелье"} -- создаём список предметов
print(items[1]) -- выводим первый элемент: "Меч"
print(#items) -- выводим количество элементов: 3
</code>
<t>Массивы удобны, когда важен порядок элементов.</t>

<h>Хэш-таблица, или словарь</h>
<t>Хэш-таблица — это таблица, где ключами могут быть строки, числа и другие значения, кроме <k>nil</k>.</t>
<code>
local player = {name = "Артас", level = 80} -- создаём словарь
print(player.name) -- читаем поле name: "Артас"
print(player["level"]) -- читаем поле level: 80
</code>
<t>Хэш-таблицы удобны, когда данные имеют имена.</t>

<h>Чем массив отличается от хэш-таблицы</h>
<c>Массив:</c> доступ по номеру, порядок сохранён, можно использовать оператор <k>#</k>.
<c>Хэш-таблица:</c> доступ по имени или другому ключу, порядок через <k>pairs</k> не гарантирован, оператор <k>#</k> обычно не используют.

<h>Память</h>
<t>Массивная часть таблицы хранится компактно, поэтому списки обычно занимают меньше памяти.</t>
<t>Хэш-часть хранит ключи, значения и служебную информацию для быстрого поиска, поэтому словари обычно занимают больше памяти.</t>
<w>Вывод:</w> если данные можно хранить как список — лучше хранить как список. Словарь нужен, когда нужны именованные поля или быстрый поиск по ключу.

<h>Когда использовать хэш-таблицы</h>
<t>- нужно найти значение по имени;</t>
<t>- нужно хранить настройки;</t>
<t>- нужно сопоставить предмет и цену;</t>
<t>- нужно быстро проверить, есть ли ключ;</t>
<t>- нужно описать объект с полями.</t>

<h>Перебор</h>
<t>Для массивов используют <k>ipairs</k>:</t>
<code>
local items = {"Меч", "Щит"} -- список
for index, value in ipairs(items) do -- перебираем по порядку
    print(index, value) -- выводим номер и значение
end
</code>
<t>Для словарей используют <k>pairs</k>:</t>
<code>
local prices = {["Факел"] = 10, ["Компас"] = 100} -- словарь цен
for key, value in pairs(prices) do -- перебираем ключи и значения
    print(key, value) -- выводим ключ и значение
end
</code>
<w>Важно:</w> порядок обхода через <k>pairs</k> не гарантирован.
]=],
}

ns_llua['lua'][44.1] = {
    type = "commenttest",
    title = "Практика: базовая сортировка через table.sort",
    helpModules = {44, 29.1},
    preloadVars = {
        {var = "sortNumbers", desc = "sortNumbers очищается перед проверкой"},
    },
    reportVars = {"sortNumbers"},
    instruction = [=[
<h>Практика: базовая сортировка</h>
<t>Функция <k>table.sort</k> сортирует массив на месте.</t>
<t>То есть она меняет саму таблицу, а не возвращает новую.</t>

<t>Создай глобальную таблицу <k>sortNumbers</k> с числами:</t>
<s>7, 1, 5, 3</s>

<t>Отсортируй её по возрастанию через <k>table.sort</k>.</t>

<t>Ожидаемый результат:</t>
<code>
sortNumbers = {1, 3, 5, 7}
</code>

<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, таблица нужна глобальная.</w>
]=],
    initialCode = [=[
-- Создай sortNumbers и отсортируй её через table.sort
]=],
    requireKeywords = {
        "sortNumbers",
        "table.sort",
    },
    checkCode = function()
        return type(_G.sortNumbers) == "table"
            and #_G.sortNumbers == 4
            and _G.sortNumbers[1] == 1
            and _G.sortNumbers[2] == 3
            and _G.sortNumbers[3] == 5
            and _G.sortNumbers[4] == 7
    end,
}

ns_llua['lua'][45] = {
    type = "info",
    title = "Функции",
    helpModules = {44},
    content = [=[
<h>Функции</h>
<t>Функция — это блок кода, который можно вызывать много раз.</t>
<t>Функции помогают не повторять один и тот же код и разбивать программу на маленькие понятные части.</t>

<h>Объявление функции</h>
<code>
local function sum(a, b) -- объявляем локальную функцию
    return a + b -- возвращаем результат
end
print(sum(2, 3)) -- вызываем функцию и выводим 5
</code>

<h>Аргументы</h>
<t>Функция может принимать значения внутри скобок.</t>
<code>
local function greet(name) -- функция принимает аргумент name
    return "Привет, " .. name -- возвращаем строку
end
print(greet("Артас")) -- выводим: Привет, Артас
</code>

<h>return</h>
<t>Оператор <k>return</k> возвращает значение из функции.</t>
<code>
local function isAdult(age) -- функция проверки возраста
    if age >= 18 then -- если возраст подходит
        return true -- возвращаем true
    end
    return false -- иначе возвращаем false
end
</code>

<h>Несколько возвращаемых значений</h>
<t>Некоторые функции WoW API возвращают сразу несколько значений.</t>
<code>
local className, classToken = UnitClass("player") -- получаем два значения от UnitClass
print(className) -- выводим название класса, например "Воин"
print(classToken) -- выводим код класса, например "WARRIOR"
</code>

<t>Здесь одна функция вернула сразу два результата:</t>
<t>- <k>className</k> — понятное название класса;</t>
<t>- <k>classToken</k> — технический код класса.</t>

<t>Если первое значение не нужно, вместо него ставят <k>_</k>.</t>
<code>
local _, classToken = UnitClass("player") -- получаем только второй результат
print(classToken) -- выводим код класса, например "WARRIOR"
</code>

<h>Локальные и глобальные функции</h>
<code>
local function localSum(a, b) -- локальная функция
    return a + b -- возвращает сумму
end
function globalSum(a, b) -- глобальная функция
    return a + b -- возвращает сумму
end
</code>
<t>Локальные функции обычно лучше: они не засоряют глобальную область видимости и работают быстрее.</t>
<w>Важно для курса:</w> если практическое задание просит создать функцию для проверки, делай её глобальной, чтобы система могла её вызвать.

<h>Досрочный return</h>
<t>Из функции можно выйти раньше времени.</t>
<code>
local function getPrice(list, key) -- функция получения цены
    if type(list) ~= "table" then return 0 end -- если список не таблица, возвращаем 0
    return list[key] or 0 -- если ключа нет, возвращаем 0
end
</code>

<h>Зачем выносить логику в функции</h>
<t>- код становится короче;</t>
<t>- логику можно проверить отдельно;</t>
<t>- одну функцию можно использовать с разными данными;</t>
<t>- проще искать ошибки.</t>
]=],
}

ns_llua['lua'][45.1] = {
    type = "commenttest",
    title = "Практика: сортировка со своим условием",
    helpModules = {45, 44.1},
    preloadVars = {
        {var = "sortDesc", desc = "sortDesc очищается перед проверкой"},
    },
    reportVars = {"sortDesc"},
    instruction = [=[
<h>Практика: сортировка со своим условием</h>
<t>По умолчанию <k>table.sort</k> сортирует элементы по возрастанию.</t>
<t>Если нужен другой порядок, в функцию сравнения передают вторым аргументом.</t>

<t>Функция сравнения должна вернуть <k>true</k>, если первый аргумент должен стоять раньше второго.</t>

<t>Пример сортировки по убыванию:</t>
<code>
table.sort(t, function(a, b)
    return a > b
end)
</code>

<h>Задание</h>
<t>Создай глобальную таблицу <k>sortDesc</k> с числами:</t>
<s>3, 8, 1, 5</s>

<t>Отсортируй её по убыванию через <k>table.sort</k> и свою функцию сравнения.</t>

<t>Ожидаемый результат:</t>
<code>
sortDesc = {8, 5, 3, 1}
</code>

<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, таблица нужна глобальная.</w>
]=],
    initialCode = [=[
-- Создай sortDesc и отсортируй её по убыванию
]=],
    requireKeywords = {
        "sortDesc",
        "table.sort",
        "function",
        "return",
    },
    checkCode = function()
        return type(_G.sortDesc) == "table"
            and #_G.sortDesc == 4
            and _G.sortDesc[1] == 8
            and _G.sortDesc[2] == 5
            and _G.sortDesc[3] == 3
            and _G.sortDesc[4] == 1
    end,
}

ns_llua['lua'][45.2] = {
type = "info",
title = "Функция select",
helpModules = {45},
content = [=[
<h>Функция select</h>
<t>Функция <k>select</k> позволяет доставать значения из списка аргументов.</t>
<h>Выбор значений</h>
<t>Первый аргумент <k>select</k> — это позиция. Возвращаются все значения, начиная с этой позиции.</t>
<code>
print(select(2, "a", "b", "c")) -- b c
</code>
<t>Если присвоить результат одной переменной, возьмётся первое из возвращённых значений:</t>
<code>
local x = select(2, "a", "b", "c")
print(x) -- b
</code>
<h>select и несколько возвращаемых значений</h>
<t>Если функция возвращает несколько значений, с помощью <k>select</k> можно достать конкретное значение.</t>
<code>
local function getPlayerInfo()
return "Артас", 80, "Воин"
end
local name = select(1, getPlayerInfo())
local level = select(2, getPlayerInfo())
local class = select(3, getPlayerInfo())
print(name)  -- Артас
print(level) -- 80
print(class) -- Воин
</code>
<t>Здесь <k>select(2, getPlayerInfo())</k> возвращает второе и все последующие значения.</t>
<t>Но так как результат присваивается одной переменной, сохраняется только первое из них, то есть второе значение функции.</t>
<h>Количество аргументов</h>
<t>Внутри функций с многоточием <k>...</k> можно получить количество переданных аргументов через <k>select('#', ...)</k>.</t>
<code>
local function countArgs(...)
return select('#', ...)
end
print(countArgs())          -- 0
print(countArgs("a"))       -- 1
print(countArgs(1, 2, 3))   -- 3
</code>
<w>Важно:</w> конструкция <k>#...</k> в Lua недопустима. Для подсчёта аргументов используют именно <k>select('#', ...)</k>.
<t>Также <k>select('#', ...)</k> считает и <k>nil</k>-аргументы:</t>
<code>
local function countArgs(...)
return select('#', ...)
end
print(countArgs(nil))        -- 1
print(countArgs(1, 2, nil))  -- 3
</code>
<h>Доступ к аргументам по индексу</h>
<t>Чтобы достать конкретный аргумент из <k>...</k>, используй <k>select</k> с номером позиции:</t>
<code>
local function showArgs(...)
local n = select('#', ...)
for i = 1, n do
local arg = select(i, ...)
print(i, arg)
end
end
showArgs("a", "b", "c")
-- 1  a
-- 2  b
-- 3  c
</code>
<w>Важно:</w> <k>select(i, ...)</k> возвращает все значения, начиная с позиции <k>i</k>. Но если присвоить результат одной переменной, сохранится только первое из них — то есть именно <k>i</k>-й аргумент.
<h>Зачем это нужно</h>
<t>- получить конкретное значение из функции, которая возвращает несколько результатов;</t>
<t>- посчитать количество аргументов в функции с <k>...</k>;</t>
<t>- достать конкретный аргумент из <k>...</k> по его номеру;</t>
<t>- работать со списком аргументов без создания промежуточных таблиц.</t>
]=],
}

ns_llua['lua'][45.3] = {
    type = "commenttest",
    title = "Практика: select — выбор значения по номеру",
    helpModules = {45, 45.2},
    preloadVars = {
        {var = "selectSecond", desc = "selectSecond очищается перед проверкой"},
        {var = "selectThird", desc = "selectThird очищается перед проверкой"},
    },
    reportVars = {"selectSecond", "selectThird"},
    instruction = [=[
<h>Практика: select — выбор значения по номеру</h>

<t>В этом задании нужно использовать <k>select</k> со строками, перечисленными прямо в вызове.</t>

<t>Здесь "список строк" — это не таблица.</t>
<t>Это три строки, которые ты пишешь через запятую внутри вызова <k>select</k>:</t>

<s>"Меч", "Щит", "Зелье"</s>

<t>1. Создай глобальную переменную <k>selectSecond</k>.</t>
<t>Используй <k>select</k> с номером 2 и этими тремя строками.</t>
<t>Ожидаемое значение переменной <k>selectSecond</k>:</t>
<s>"Щит"</s>

<t>2. Создай глобальную переменную <k>selectThird</k>.</t>
<t>Используй <k>select</k> с номером 3 и этими тремя строками.</t>
<t>Ожидаемое значение переменной <k>selectThird</k>:</t>
<s>"Зелье"</s>

<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, переменные нужны глобальные.</w>
]=],
    initialCode = [=[
-- Создай selectSecond и selectThird через select
]=],
    requireKeywords = {
        "selectSecond",
        "selectThird",
        "select(2",
        "select(3",
    },
    forbidKeywords = {
        'selectSecond="Щит"',
        "selectSecond='Щит'",
        'selectThird="Зелье"',
        "selectThird='Зелье'",
    },
    checkCode = function()
        return _G.selectSecond == "Щит"
            and _G.selectThird == "Зелье"
    end,
}

ns_llua['lua'][45.4] = {
    type = "commenttest",
    title = "Практика: select('#', ...) и количество возвращаемых значений WoW API",
    helpModules = {45, 45.2},
    preloadVars = {
        {var = "unitClassCount", desc = "unitClassCount очищается перед проверкой"},
        {var = "unitRaceCount", desc = "unitRaceCount очищается перед проверкой"},
        {var = "unitHealthCount", desc = "unitHealthCount очищается перед проверкой"},
    },
    reportVars = {"unitClassCount", "unitRaceCount", "unitHealthCount"},
    instruction = [=[
<h>Практика: количество возвращаемых значений функций WoW API</h>

<t>В Lua нельзя напрямую узнать, сколько параметров принимает функция.</t>
<t>Но можно узнать, сколько значений функция возвращает.</t>

<t>Для этого используется конструкция:</t>

<code>
select('#', SomeFunction())
</code>

<t>В этом задании нужно посчитать количество возвращаемых значений у трёх функций WoW API.</t>

<t>1. Создай глобальную переменную <k>unitClassCount</k>.</t>
<t>Сохрани в неё количество значений, которое возвращает функция:</t>
<k>UnitClass("player")</k>

<t>2. Создай глобальную переменную <k>unitRaceCount</k>.</t>
<t>Сохрани в неё количество значений, которое возвращает функция:</t>
<k>UnitRace("player")</k>

<t>3. Создай глобальную переменную <k>unitHealthCount</k>.</t>
<t>Сохрани в неё количество значений, которое возвращает функция:</t>
<k>UnitHealth("player")</k>

<t>Форма вызова:</t>

<code>
unitClassCount = select('#', UnitClass("player"))
</code>

<t>Числа руками не вписывай. Их должен вернуть <k>select</k>.</t>

<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, переменные нужны глобальные.</w>
]=],
    initialCode = [=[
-- Посчитай количество возвращаемых значений функций WoW API
]=],
    requireKeywords = {
        "unitClassCount=select(",
        "unitRaceCount=select(",
        "unitHealthCount=select(",
        "#",
        "UnitClass(",
        "UnitRace(",
        "UnitHealth(",
        "player",
    },
    forbidKeywords = {
        "unitClassCount=2",
        "unitRaceCount=2",
        "unitHealthCount=1",
    },
    checkCode = function()
        local okClass, expectedClass = pcall(function()
            return select('#', UnitClass("player"))
        end)

        local okRace, expectedRace = pcall(function()
            return select('#', UnitRace("player"))
        end)

        local okHealth, expectedHealth = pcall(function()
            return select('#', UnitHealth("player"))
        end)

        if not okClass or not okRace or not okHealth then
            return false
        end

        return _G.unitClassCount == expectedClass
            and _G.unitRaceCount == expectedRace
            and _G.unitHealthCount == expectedHealth
    end,
}

ns_llua['lua'][45.5] = {
    type = "commenttest",
    title = "Практика: select и второй результат UnitClass",
    helpModules = {45, 45.2, 45.4},
    preloadVars = {
        {var = "playerClassToken", desc = "playerClassToken очищается перед проверкой"},
    },
    reportVars = {"playerClassToken"},
    instruction = [=[
<h>Практика: второй результат UnitClass</h>

<t>Функция <k>UnitClass("player")</k> возвращает несколько значений: имя класса и код класса.</t>

<t>Создай глобальную переменную <k>playerClassToken</k>.</t>
<t>Сохрани в неё второй результат функции <k>UnitClass("player")</k> через <k>select</k>.</t>

<t>Форма вызова:</t>
<code>
playerClassToken = select(2, UnitClass("player"))
</code>

<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k> для переменной <k>playerClassToken</k>, она нужна глобальная.</w>
]=],
    initialCode = [=[
-- Получи второй результат UnitClass("player")
]=],
    requireKeywords = {
        "playerClassToken=select(",
        "select(2",
        "UnitClass(",
        "player",
    },
    forbidKeywords = {
        'playerClassToken="',
        "playerClassToken='",
    },
    checkCode = function()
        local ok, expected = pcall(function()
            return select(2, UnitClass("player"))
        end)

        if not ok then
            return false
        end

        return type(_G.playerClassToken) == "string"
            and _G.playerClassToken ~= ""
            and _G.playerClassToken == expected
    end,
}

ns_llua['lua'][45.6] = {
type = "commenttest",
title = "Практика: select и конкретные аргументы из (...)",
helpModules = {45, 45.2},
preloadVars = {
{var = "getFirst", desc = "getFirst очищается перед проверкой"},
{var = "getThird", desc = "getThird очищается перед проверкой"},
},
reportVars = {},
instruction = [=[
<h>Практика: select и конкретные аргументы из (...)</h>
<t>В этом задании циклы не нужны.</t>
<t>Нужно просто достать конкретный аргумент из <k>...</k> по его номеру через <k>select</k>.</t>
<t>Напоминание:</t>
<code>
select(1, ...) -- первый аргумент
select(2, ...) -- второй аргумент
select(3, ...) -- третий аргумент
</code>
<t>Если присвоить результат одной переменной, сохранится только первое из возвращённых значений, то есть именно аргумент под этим номером.</t>
<t>1. Создай глобальную функцию <k>getFirst(...)</k>.</t>
<t>Функция должна вернуть первый переданный аргумент.</t>
<t>Используй <k>select(1, ...)</k>.</t>
<t>2. Создай глобальную функцию <k>getThird(...)</k>.</t>
<t>Функция должна вернуть третий переданный аргумент.</t>
<t>Используй <k>select(3, ...)</k>.</t>
<t>Если аргумента под нужным номером нет, функция вернёт <k>nil</k> — это нормально.</t>
<t>Ожидаемое поведение:</t>
<code>
getFirst(10, 20, 30)    -- 10
getFirst("a")           -- a
getFirst()              -- nil
getThird(10, 20, 30)    -- 30
getThird("x", "y", "z") -- z
getThird(1)             -- nil
</code>
<t>Ничего выводить не нужно.</t>
<w>Сама функция должна быть глобальной. Вспомогательные переменные внутри функции могут быть <k>local</k>.</w>
]=],
initialCode = [=[
-- Создай функции getFirst(...) и getThird(...)
]=],
requireKeywords = {
"getFirst",
"getThird",
"function",
"...",
"select(1",
"select(3",
"return",
},
checkCode = function()
local details = {}
if type(_G.getFirst) ~= "function" then
return "getFirst не является функцией"
end
if type(_G.getThird) ~= "function" then
return "getThird не является функцией"
end
local ok, r
ok, r = pcall(_G.getFirst, 10, 20, 30)
if not ok or r ~= 10 then
table.insert(details, "getFirst(10, 20, 30): получилось " .. tostring(r) .. ", ожидалось 10")
end
ok, r = pcall(_G.getFirst, "a")
if not ok or r ~= "a" then
table.insert(details, "getFirst(\"a\"): получилось " .. tostring(r) .. ", ожидалось \"a\"")
end
ok, r = pcall(_G.getFirst)
if not ok or r ~= nil then
table.insert(details, "getFirst(): получилось " .. tostring(r) .. ", ожидалось nil")
end
ok, r = pcall(_G.getThird, 10, 20, 30)
if not ok or r ~= 30 then
table.insert(details, "getThird(10, 20, 30): получилось " .. tostring(r) .. ", ожидалось 30")
end
ok, r = pcall(_G.getThird, "x", "y", "z")
if not ok or r ~= "z" then
table.insert(details, "getThird(\"x\", \"y\", \"z\"): получилось " .. tostring(r) .. ", ожидалось \"z\"")
end
ok, r = pcall(_G.getThird, 1)
if not ok or r ~= nil then
table.insert(details, "getThird(1): получилось " .. tostring(r) .. ", ожидалось nil")
end
if #details > 0 then
return table.concat(details, "\n")
end
return true
end,
}

ns_llua['lua'][45.7] = {
type = "commenttest",
title = "Практика: функция getLast(...)",
helpModules = {45, 45.2, 45.6},
preloadVars = {
{var = "getLast", desc = "getLast очищается перед проверкой"},
},
reportVars = {},
instruction = [=[
<h>Практика: функция getLast(...)</h>
<t>Создай глобальную функцию <k>getLast(...)</k>.</t>
<t>Функция должна возвращать последний переданный ей аргумент.</t>
<t>Если аргументов нет, функция должна вернуть <k>nil</k>.</t>
<t>Цикл здесь не нужен.</t>
<t>Алгоритм:</t>
<t>1. Узнай количество аргументов через <k>select('#', ...)</k>.</t>
<t>2. Если количество равно 0, верни <k>nil</k>.</t>
<t>3. Иначе достань последний аргумент через <k>select(n, ...)</k>, где <k>n</k> — количество аргументов.</t>
<t>Ожидаемое поведение:</t>
<code>
getLast(1, 2, 3)     -- 3
getLast("a")         -- a
getLast()            -- nil
getLast(1, nil, 3)   -- 3
getLast(nil, "x")    -- x
</code>
<t>Ничего выводить не нужно.</t>
<w>Сама функция должна быть глобальной. Вспомогательные переменные внутри функции могут быть <k>local</k>.</w>
]=],
initialCode = [=[
-- Создай функцию getLast(...)
]=],
requireKeywords = {
"getLast",
"function",
"...",
"select",
"#",
"return",
},
checkCode = function()
local details = {}
if type(_G.getLast) ~= "function" then
return "getLast не является функцией"
end
local ok, r
ok, r = pcall(_G.getLast, 1, 2, 3)
if not ok or r ~= 3 then
table.insert(details, "getLast(1, 2, 3): получилось " .. tostring(r) .. ", ожидалось 3")
end
ok, r = pcall(_G.getLast, "a")
if not ok or r ~= "a" then
table.insert(details, "getLast(\"a\"): получилось " .. tostring(r) .. ", ожидалось \"a\"")
end
ok, r = pcall(_G.getLast)
if not ok or r ~= nil then
table.insert(details, "getLast(): получилось " .. tostring(r) .. ", ожидалось nil")
end
ok, r = pcall(_G.getLast, 1, nil, 3)
if not ok or r ~= 3 then
table.insert(details, "getLast(1, nil, 3): получилось " .. tostring(r) .. ", ожидалось 3")
end
ok, r = pcall(_G.getLast, nil, "x")
if not ok or r ~= "x" then
table.insert(details, "getLast(nil, \"x\"): получилось " .. tostring(r) .. ", ожидалось \"x\"")
end
if #details > 0 then
return table.concat(details, "\n")
end
return true
end,
}

ns_llua['lua'][45.8] = {
type = "commenttest",
title = "Практика: функция sumNumbers(...)",
helpModules = {45, 45.2, 31},
preloadVars = {
{var = "sumNumbers", desc = "sumNumbers очищается перед проверкой"},
},
reportVars = {},
instruction = [=[
<h>Практика: функция sumNumbers(...)</h>
<t>Создай глобальную функцию <k>sumNumbers(...)</k>.</t>
<t>Функция должна вернуть сумму только тех аргументов, у которых тип <k>number</k>.</t>
<t>Если числовых аргументов нет, функция должна вернуть 0.</t>
<t>Здесь уже нужен цикл.</t>
<t>Алгоритм:</t>
<t>1. Узнай количество аргументов через <k>select('#', ...)</k>.</t>
<t>2. Запусти цикл <k>for</k> от 1 до этого количества.</t>
<t>3. На каждом шаге достань аргумент через <k>select(i, ...)</k>.</t>
<t>4. Проверь тип через <k>type</k>. Если это <k>number</k>, прибавь к сумме.</t>
<t>Ожидаемое поведение:</t>
<code>
sumNumbers(1, 2, 3)        -- 6
sumNumbers(10, "x", 5)     -- 15
sumNumbers("a", "b")       -- 0
sumNumbers(1.5, 2.5)       -- 4
sumNumbers(nil, 5)         -- 5
sumNumbers()               -- 0
</code>
<t>Ничего выводить не нужно.</t>
<w>Сама функция должна быть глобальной. Вспомогательные переменные внутри функции могут быть <k>local</k>.</w>
]=],
initialCode = [=[
-- Создай функцию sumNumbers(...)
]=],
requireKeywords = {
"sumNumbers",
"function",
"...",
"select",
"#",
"type",
"for",
"return",
},
checkCode = function()
local details = {}
if type(_G.sumNumbers) ~= "function" then
return "sumNumbers не является функцией"
end
local ok, r
ok, r = pcall(_G.sumNumbers)
if not ok or r ~= 0 then
table.insert(details, "sumNumbers(): получилось " .. tostring(r) .. ", ожидалось 0")
end
ok, r = pcall(_G.sumNumbers, 1, 2, 3)
if not ok or r ~= 6 then
table.insert(details, "sumNumbers(1, 2, 3): получилось " .. tostring(r) .. ", ожидалось 6")
end
ok, r = pcall(_G.sumNumbers, 10, "x", 5)
if not ok or r ~= 15 then
table.insert(details, "sumNumbers(10, \"x\", 5): получилось " .. tostring(r) .. ", ожидалось 15")
end
ok, r = pcall(_G.sumNumbers, "a", "b")
if not ok or r ~= 0 then
table.insert(details, "sumNumbers(\"a\", \"b\"): получилось " .. tostring(r) .. ", ожидалось 0")
end
ok, r = pcall(_G.sumNumbers, 1.5, 2.5)
if not ok or r ~= 4 then
table.insert(details, "sumNumbers(1.5, 2.5): получилось " .. tostring(r) .. ", ожидалось 4")
end
ok, r = pcall(_G.sumNumbers, nil, 5)
if not ok or r ~= 5 then
table.insert(details, "sumNumbers(nil, 5): получилось " .. tostring(r) .. ", ожидалось 5")
end
if #details > 0 then
return table.concat(details, "\n")
end
return true
end,
}

ns_llua['lua'][46] = {
    type = "commenttest",
    title = "Практика: функция sumStats",
    helpModules = {44, 45, 4},
    preloadVars = {
        {var = "sumStats", desc = "sumStats очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
    },
    instruction = [=[
<h>Практика: функция sumStats</h>
<t>Создай только глобальную функцию <k>sumStats(stats)</k>.</t>

<t>Функция получает хэш-таблицу <k>stats</k>.</t>
<t>Значения в таблице могут быть числами и не числами.</t>
<t>Функция должна вернуть сумму только тех значений, у которых тип <k>number</k>.</t>

<t>Используй:</t>
<t>- <k>pairs</k>;</t>
<t>- <k>type</k>;</t>
<t>- <k>return</k>.</t>

<w>Важно:</w>
<t>Таблицу создавать не нужно.</t>
<t>Система сама подставит свои таблицы в твою функцию во время проверки.</t>

<t>После проверки в отчёте будет показано:</t>
<t>- какая таблица подавалась в функцию;</t>
<t>- какой результат вернула функция;</t>
<t>- какой результат ожидался.</t>

<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Создай глобальную функцию sumStats(stats)
]=],
    requireKeywords = {
        "sumStats",
        "function",
        "pairs",
        "type",
        "return",
    },
    checkCode = function()
        local function formatValue(value)
            if type(value) == "string" then
                return '"' .. value .. '"'
            end

            return tostring(value)
        end

        local function serializeTable(t)
            local keys = {}

            for k in pairs(t) do
                table.insert(keys, k)
            end

            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b)
            end)

            local parts = {}

            for _, k in ipairs(keys) do
                table.insert(parts, tostring(k) .. "=" .. formatValue(t[k]))
            end

            return "{" .. table.concat(parts, ", ") .. "}"
        end

        local function copyTable(t)
            local out = {}

            for k, v in pairs(t) do
                out[k] = v
            end

            return out
        end

        _G.checkError = nil
        _G.test1 = nil
        _G.test2 = nil
        _G.test3 = nil
        _G.test4 = nil

        if type(_G.sumStats) ~= "function" then
            _G.checkError = "sumStats не является глобальной функцией"
            return false
        end

        local tests = {
            {
                input = {
                    strength = 20,
                    agility = 15,
                    intellect = 30,
                },
                expected = 65,
            },
            {
                input = {
                    hp = 100,
                    name = "Герой",
                    stamina = 25,
                },
                expected = 125,
            },
            {
                input = {
                    one = 7,
                },
                expected = 7,
            },
            {
                input = {},
                expected = 0,
            },
        }

        local allOk = true

        for i, test in ipairs(tests) do
            local inputCopy = copyTable(test.input)
            local ok, result = pcall(_G.sumStats, test.input)

            local resultText

            if ok then
                resultText = formatValue(result)
            else
                resultText = "ошибка: " .. tostring(result)
            end

            _G["test" .. i] = "Таблица: "
                .. serializeTable(inputCopy)
                .. " | Результат: "
                .. resultText
                .. " | Ожидалось: "
                .. formatValue(test.expected)

            if not ok or result ~= test.expected then
                allOk = false
            end
        end

        return allOk
    end,
}

ns_llua['lua'][46.1] = {
    type = "commenttest",
    title = "Практика: сортировка таблицы объектов через компаратор",
    helpModules = {45, 45.1, 44.1},
    preloadVars = {
        {var = "sortPlayers", desc = "sortPlayers очищается перед проверкой"},
    },
    reportVars = {"sortPlayers"},
    instruction = [=[
<h>Практика: сортировка таблицы объектов через компаратор</h>
<t>Создай глобальную таблицу <k>sortPlayers</k>.</t>

<t>Добавь в неё три элемента. Каждый элемент должен быть таблицей с полями <k>name</k> и <k>level</k>.</t>

<t>Данные для заполнения:</t>
<t>- первый игрок: имя <s>"Тралл"</s>, уровень 60;</t>
<t>- второй игрок: имя <s>"Артас"</s>, уровень 80;</t>
<t>- третий игрок: имя <s>"Джайна"</s>, уровень 75.</t>

<t>После этого отсортируй таблицу <k>sortPlayers</k> так, чтобы первыми шли игроки с более высоким уровнем.</t>

<h>Как сортировать подтаблицы по нужному ключу</h>
<t>Если внутри таблицы лежат таблицы-объекты, сортировать нужно саму внешнюю таблицу, а не каждый внутренний объект отдельно.</t>

<t>Функция сравнения получает два элемента внешней таблицы. В этой задаче каждый элемент — это таблица с полями <k>name</k> и <k>level</k>.</t>

<t>Абстрактный приём сортировки по нужному ключу:</t>

<code>
local sortKey = "someField"

table.sort(outerTable, function(a, b)
    return a[sortKey] > b[sortKey]
end)
</code>

<t>Или напрямую через строковый ключ:</t>

<code>
table.sort(outerTable, function(a, b)
    return a["someField"] > b["someField"]
end)
</code>

<t>Замени <k>someField</k> на имя того поля, по которому нужно сортировать.</t>

<t>Знак больше даёт сортировку по убыванию. Знак меньше даёт сортировку по возрастанию.</t>

<w>Цикл для сортировки не нужен: <k>table.sort</k> вызывается один раз для всей таблицы <k>sortPlayers</k>.</w>

<t>Ожидаемый порядок после сортировки:</t>
<t>1. Артас, уровень 80</t>
<t>2. Джайна, уровень 75</t>
<t>3. Тралл, уровень 60</t>

<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k> для таблицы <k>sortPlayers</k>, она нужна глобальная.</w>
]=],
    initialCode = [=[
-- Создай sortPlayers, добавь игроков и отсортируй их по нужному полю
]=],
    requireKeywords = {
        "sortPlayers",
        "table.sort",
        "function",
        "return",
        "level",
    },
    checkCode = function()
        return type(_G.sortPlayers) == "table"
            and #_G.sortPlayers == 3
            and type(_G.sortPlayers[1]) == "table"
            and type(_G.sortPlayers[2]) == "table"
            and type(_G.sortPlayers[3]) == "table"
            and _G.sortPlayers[1].name == "Артас"
            and _G.sortPlayers[1].level == 80
            and _G.sortPlayers[2].name == "Джайна"
            and _G.sortPlayers[2].level == 75
            and _G.sortPlayers[3].name == "Тралл"
            and _G.sortPlayers[3].level == 60
    end,
}

ns_llua['lua'][47] = {
    type = "commenttest",
    title = "Практика: чтение полей хэш-таблицы",
    helpModules = {44},
    preloadVars = {
        {var = "hero", value = {name = "Тралл", level = 60, ["класс"] = "Шаман"}, desc = "hero = {name = \"Тралл\", level = 60, [\"класс\"] = \"Шаман\"}"},
        {var = "key", value = "level", desc = "key = \"level\" (переменная с именем ключа)"},
        {var = "heroName", desc = "heroName очищается перед проверкой"},
        {var = "heroLevel", desc = "heroLevel очищается перед проверкой"},
        {var = "heroClass", desc = "heroClass очищается перед проверкой"},
        {var = "heroByKey", desc = "heroByKey очищается перед проверкой"},
    },
    reportVars = {"heroName", "heroLevel", "heroClass", "heroByKey", "hero", "key"},
    instruction = [=[
<h>Три способа обратиться к полю</h>
<c>hero.name</c> — ключ написан руками, только латиница. Ищет буквально "name".
<c>hero["name"]</c> — ключ написан руками в кавычках. То же самое, что точка, но работает и с кириллицей.
<c>hero[key]</c> — ключ берётся из переменной. Кавычек НЕТ. Ищет то, что лежит в key.

<w>Точка и ["строка"] ищут буквальный ключ. [переменная] подставляет значение переменной. Это разные вещи.</w>

<h>Ловушка</h>
<t>Если имя ключа лежит в переменной, точка не подойдёт:</t>
<c>hero.key</c> — ищет строку "key".
<c>hero[key]</c> — подставляет переменную key="level", ищет "level" = 60.

<h>Задание</h>
<t>Таблица <k>hero</k> и переменная <k>key</k> = "level" уже созданы. Прочитай поля четырьмя способами:</t>
<t>- <k>heroName</k> = поле name через точку;</t>
<t>- <k>heroLevel</k> = поле level через скобки со строкой;</t>
<t>- <k>heroClass</k> = поле класс через скобки со строкой (кириллица, точка тут запрещена);</t>
<t>- <k>heroByKey</k> = поле, имя которого в переменной key, через скобки с переменной (без кавычек).</t>
<t>В скобках со строкой используй двойные кавычки. Таблицу не создавай. Ничего не выводи.</t>
]=],
    initialCode = [=[
-- Прочитай поля таблицы hero четырьмя способами
]=],
    requireKeywords = {
        "heroName",
        "heroLevel",
        "heroClass",
        "heroByKey",
        "hero.name",
        'hero["level"]',
        'hero["класс"]',
        "hero[key]",
    },
    checkCode = function()
        return type(_G.heroName) == "string"
            and _G.heroName == "Тралл"
            and type(_G.heroLevel) == "number"
            and _G.heroLevel == 60
            and type(_G.heroClass) == "string"
            and _G.heroClass == "Шаман"
            and type(_G.heroByKey) == "number"
            and _G.heroByKey == 60
    end,
}

ns_llua['lua'][48] = {
    type = "commenttest",
    title = "Практика: запись полей хэш-таблицы",
    helpModules = {44},
    preloadVars = {
        {var = "item", value = {}, desc = "item = {} (пустая таблица)"},
    },
    reportVars = {"item"},
    instruction = [=[
<h>Практика: запись полей хэш-таблицы</h>
<t>Глобальная таблица <k>item</k> уже создана, пока она пустая.</t>

<t>Заполни её поля двумя разными способами:</t>
<t>- поле <k>name</k> запиши через точку, значение <s>"Меч"</s>;</t>
<t>- поле <k>quality</k> запиши через квадратные скобки, значение <s>"Эпический"</s>;</t>
<t>- поле <k>price</k> запиши через квадратные скобки, значение <n>100</n>;</t>
<t>- поле <k>stack</k> запиши через точку, значение <n>5</n>.</t>

<h>Подсказка по синтаксису</h>
<t>Запись через точку выглядит так: <c>имя.поле = значение</c></t>
<t>Запись через скобки выглядит так: <c>имя["поле"] = значение</c></t>
<w>Важно:</w> внутри квадратных скобок используй именно двойные кавычки.

<t>Таблицу создавать не нужно, она уже есть. Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Заполни поля таблицы item двумя способами
]=],
    requireKeywords = {
        "item.name",
        'item["quality"]',
        'item["price"]',
        "item.stack",
    },
    checkCode = function()
        return type(_G.item) == "table"
            and _G.item.name == "Меч"
            and _G.item.quality == "Эпический"
            and _G.item.price == 100
            and _G.item.stack == 5
    end,
}

ns_llua['lua'][49] = {
    type = "commenttest",
    title = "Практика: чтение и запись двумя способами",
    helpModules = {44},
    preloadVars = {
        {var = "source", value = {name = "Клинок", price = 100}, desc = "source = {name = \"Клинок\", price = 100}"},
        {var = "copy", desc = "copy очищается перед проверкой"},
    },
    reportVars = {"copy", "source"},
    instruction = [=[
<h>Практика: чтение и запись двумя способами</h>
<t>Глобальная таблица <k>source</k> уже создана. В ней поля <k>name</k> и <k>price</k>.</t>
<w>Важно:</w> таблицу <k>source</k> менять нельзя. Мы только читаем из неё.</t>

<t>Создай новую глобальную таблицу <k>copy</k> (пустую).</t>
<t>Скопируй в неё данные из <k>source</k> и добавь свои поля, используя оба синтаксиса и на чтение, и на запись:</t>
<t>- <k>copy.name</k> присвой значение <k>source.name</k> (чтение и запись через точку);</t>
<t>- <k>copy["price"]</k> присвой значение <k>source["price"]</k> (чтение и запись через скобки);</t>
<t>- добавь новое поле <k>copy["quality"]</k> со значением <s>"Редкий"</s> (запись через скобки);</t>
<t>- добавь новое поле <k>copy.stack</k> со значением <n>1</n> (запись через точку).</t>

<h>Подсказка по синтаксису</h>
<t>Через точку: <c>copy.name = source.name</c></t>
<t>Через скобки: <c>copy["price"] = source["price"]</c></t>
<w>Важно:</w> внутри квадратных скобок используй именно двойные кавычки.

<t>Смысл задания: оба способа работают с одними и теми же данными таблицы.</t>
<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Создай таблицу copy и заполни её двумя способами
]=],
    requireKeywords = {
        "copy",
        "copy.name",
        "source.name",
        'copy["price"]',
        'source["price"]',
        'copy["quality"]',
        "copy.stack",
    },
    checkCode = function()
        return type(_G.copy) == "table"
            and _G.copy.name == "Клинок"
            and _G.copy.price == 100
            and _G.copy.quality == "Редкий"
            and _G.copy.stack == 1
            and type(_G.source) == "table"
            and _G.source.name == "Клинок"
            and _G.source.price == 100
    end,
}

ns_llua['lua'][50] = {
    type = "commenttest",
    title = "Практика: функция countRareItems",
    helpModules = {44, 45, 31},
    preloadVars = {
        {var = "countRareItems", desc = "countRareItems очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
    },
    instruction = [=[
<h>Практика: функция countRareItems</h>
<t>Создай только глобальную функцию <k>countRareItems(items)</k>.</t>

<t>Функция получает массив таблиц. Каждый элемент массива — это маленький словарь с информацией о предмете.</t>
<t>У предмета может быть поле <k>rare</k> со значением <k>true</k> или <k>false</k> (или его может не быть вовсе).</t>
<t>Функция должна вернуть количество предметов, у которых <k>rare == true</k>.</t>

<t>Используй:</t>
<t>- <k>ipairs</k>;</t>
<t>- <k>if</k>;</t>
<t>- <k>return</k>.</t>

<w>Важно:</w>
<t>Таблицу создавать не нужно.</t>
<t>Система сама подставит свои массивы предметов в твою функцию во время проверки.</t>

<t>После проверки в отчёте будет показано:</t>
<t>- какой массив подавался в функцию;</t>
<t>- какой результат вернула функция;</t>
<t>- какой результат ожидался.</t>

<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Создай глобальную функцию countRareItems(items)
]=],
    requireKeywords = {
        "countRareItems",
        "function",
        "ipairs",
        "return",
    },
    checkCode = function()
        local function isArray(t)
            local n = #t
            if n == 0 then
                for _ in pairs(t) do
                    return false
                end
                return true
            end

            local count = 0
            for k in pairs(t) do
                count = count + 1
                if type(k) ~= "number" or k < 1 or k > n or k ~= math.floor(k) then
                    return false
                end
            end

            return count == n
        end

        local function fmt(v, depth)
            depth = depth or 0
            local t = type(v)

            if t == "string" then
                return '"' .. v .. '"'
            elseif t == "number" or t == "boolean" then
                return tostring(v)
            elseif t == "nil" then
                return "nil"
            elseif t == "table" then
                if depth >= 2 then
                    return "{...}"
                end

                if isArray(v) then
                    local parts = {}
                    for i = 1, #v do
                        parts[i] = fmt(v[i], depth + 1)
                    end
                    return "{" .. table.concat(parts, ", ") .. "}"
                end

                local keys = {}
                for k in pairs(v) do
                    table.insert(keys, k)
                end
                table.sort(keys, function(a, b)
                    return tostring(a) < tostring(b)
                end)

                local parts = {}
                for _, k in ipairs(keys) do
                    local ks
                    if type(k) == "string" then
                        ks = '["' .. k .. '"]'
                    else
                        ks = "[" .. tostring(k) .. "]"
                    end
                    table.insert(parts, ks .. "=" .. fmt(v[k], depth + 1))
                end

                return "{" .. table.concat(parts, ", ") .. "}"
            end

            return "<" .. t .. ">"
        end

        _G.checkError = nil
        _G.test1 = nil
        _G.test2 = nil
        _G.test3 = nil
        _G.test4 = nil

        if type(_G.countRareItems) ~= "function" then
            _G.checkError = "countRareItems не является глобальной функцией"
            return false
        end

        local tests = {
            {
                input = {{rare = true}, {rare = false}, {rare = true}, {}},
                expected = 2,
            },
            {
                input = {},
                expected = 0,
            },
            {
                input = {{rare = false}, {rare = false}},
                expected = 0,
            },
            {
                input = {{rare = true}},
                expected = 1,
            },
        }

        local allOk = true

        for i, test in ipairs(tests) do
            local inputText = fmt(test.input)
            local ok, result = pcall(_G.countRareItems, test.input)

            local resultText
            if ok then
                resultText = fmt(result)
            else
                resultText = "ошибка: " .. tostring(result)
            end

            _G["test" .. i] = "Массив: "
                .. inputText
                .. " | Результат: "
                .. resultText
                .. " | Ожидалось: "
                .. fmt(test.expected)

            if not ok or result ~= test.expected then
                allOk = false
            end
        end

        return allOk
    end,
}

ns_llua['lua'][51] = {
    type = "commenttest",
    title = "Практика: функция countItemsByQuality",
    helpModules = {44, 45, 33},
    preloadVars = {
        {var = "countItemsByQuality", desc = "countItemsByQuality очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
    },
    instruction = [=[
<h>Практика: функция countItemsByQuality</h>
<t>Создай только глобальную функцию <k>countItemsByQuality(items, qualityText)</k>.</t>

<t>Функция получает хэш-таблицу <k>items</k>, где ключ — название предмета, а значение — строка с качеством.</t>
<t>Вторым аргументом идёт строка <k>qualityText</k>.</t>
<t>Функция должна вернуть количество предметов, качество которых содержит подстроку <k>qualityText</k>.</t>

<t>Используй:</t>
<t>- <k>pairs</k>;</t>
<t>- <k>string.find</k>;</t>
<t>- <k>return</k>.</t>

]=],
    initialCode = [=[
-- Создай глобальную функцию countItemsByQuality(items, qualityText)
]=],
    requireKeywords = {
        "countItemsByQuality",
        "function",
        "pairs",
        "string.find",
        "return",
    },
    checkCode = function()
        local function isArray(t)
            local n = #t
            if n == 0 then
                for _ in pairs(t) do
                    return false
                end
                return true
            end

            local count = 0
            for k in pairs(t) do
                count = count + 1
                if type(k) ~= "number" or k < 1 or k > n or k ~= math.floor(k) then
                    return false
                end
            end

            return count == n
        end

        local function fmt(v, depth)
            depth = depth or 0
            local t = type(v)

            if t == "string" then
                return '"' .. v .. '"'
            elseif t == "number" or t == "boolean" then
                return tostring(v)
            elseif t == "nil" then
                return "nil"
            elseif t == "table" then
                if depth >= 2 then
                    return "{...}"
                end

                if isArray(v) then
                    local parts = {}
                    for i = 1, #v do
                        parts[i] = fmt(v[i], depth + 1)
                    end
                    return "{" .. table.concat(parts, ", ") .. "}"
                end

                local keys = {}
                for k in pairs(v) do
                    table.insert(keys, k)
                end
                table.sort(keys, function(a, b)
                    return tostring(a) < tostring(b)
                end)

                local parts = {}
                for _, k in ipairs(keys) do
                    local ks
                    if type(k) == "string" then
                        ks = '["' .. k .. '"]'
                    else
                        ks = "[" .. tostring(k) .. "]"
                    end
                    table.insert(parts, ks .. "=" .. fmt(v[k], depth + 1))
                end

                return "{" .. table.concat(parts, ", ") .. "}"
            end

            return "<" .. t .. ">"
        end

        _G.checkError = nil
        _G.test1 = nil
        _G.test2 = nil
        _G.test3 = nil
        _G.test4 = nil

        if type(_G.countItemsByQuality) ~= "function" then
            _G.checkError = "countItemsByQuality не является глобальной функцией"
            return false
        end

        local tests = {
            {
                input = {{a = "Редкий", b = "Обычный", c = "Редкость"}, "Ред"},
                expected = 2,
            },
            {
                input = {{}, "Ред"},
                expected = 0,
            },
            {
                input = {{x = "Обычный", y = "Обычный"}, "Ред"},
                expected = 0,
            },
            {
                input = {{a = "Редкий"}, "Редкий"},
                expected = 1,
            },
        }

        local allOk = true

        for i, test in ipairs(tests) do
            local inputText = fmt(test.input[1]) .. ", " .. fmt(test.input[2])
            local ok, result = pcall(_G.countItemsByQuality, test.input[1], test.input[2])

            local resultText
            if ok then
                resultText = fmt(result)
            else
                resultText = "ошибка: " .. tostring(result)
            end

            _G["test" .. i] = "Аргументы: "
                .. inputText
                .. " | Результат: "
                .. resultText
                .. " | Ожидалось: "
                .. fmt(test.expected)

            if not ok or result ~= test.expected then
                allOk = false
            end
        end

        return allOk
    end,
}

ns_llua['lua'][51.1] = {
    type = "info",
    title = "Извлечение части строки: string.sub",
    content = [=[
<h>string.sub</h>
<t>Функция <k>string.sub</k> возвращает часть строки.</t>
<t>Первый аргумент — строка, второй — позиция начала, третий — позиция конца.</t>
<t>Позиции считаются с 1.</t>
<code>
local word = "molot"
print(string.sub(word, 1, 2)) -- "mo"
print(string.sub(word, 3, 5)) -- "lot"
</code>
<h>Синтаксический сахар через двоеточие</h>
<t>У строк в Lua есть метатаблица, поэтому функции из библиотеки <k>string</k> можно вызывать как методы самой строки.</t>
<code>
local word = "molot"
print(word:sub(1, 2)) -- "mo"
print(word:sub(3))    -- "lot"
</code>
<c>word:sub(1, 2)</c> — это сокращённая запись для <c>string.sub(word, 1, 2)</c>.
<t>То есть строка сама подставляется первым аргументом.</t>
<h>Если конец не указан</h>
<t>Без третьего аргумента берётся всё до конца строки.</t>
<code>
print(string.sub("molot", 3)) -- "lot"
print(("molot"):sub(3))       -- "lot"
</code>
<h>Отрицательные позиции</h>
<code>
print(string.sub("molot", -2)) -- "ot"
print(("molot"):sub(-2))       -- "ot"
</code>
<h>Проверка префикса</h>
<code>
local guid = "0x0000000000000001"
if string.sub(guid, 1, 6) == "0x0000" then
    print("Это игрок")
end
</code>
<t>Для латиницы, цифр и GUID позиции совпадают с символами — используй <k>string.sub</k> смело.</t>
]=],
}

ns_llua['lua'][51.2] = {
    type = "info",
    title = "Кириллица без боли: string.utf8len и string.utf8sub",
    content = [=[
<h>В чём проблема</h>
<t><k>string.len</k> и <k>string.sub</k> считают байты. Кириллица занимает 2 байта на символ, поэтому на русском и смешанном тексте позиции съезжают.</t>
<h>Готовое решение из аддона</h>
<t>Чтобы не возиться с байтами, в аддоне есть две функции, которые работают по символам:</t>
<t><k>string.utf8len(s)</k> — количество символов, а не байтов.</t>
<t><k>string.utf8sub(s, i, j)</k> — символы с i по j, как <k>string.sub</k>, но по символам. Поддерживает отрицательные индексы.</t>
<code>
print(string.utf8len("Меч"))          -- 3
print(string.utf8len("molot"))        -- 5
print(string.utf8sub("Меч", 1, 1))    -- "М"
print(string.utf8sub("Меч", 2, 3))    -- "еч"
print(string.utf8sub("Меч", -1))      -- "ч"
print(string.utf8len("Меч sword"))    -- 9: смешанный текст считается правильно
</code>
<h>Синтаксический сахар через двоеточие</h>
<code>
local word = "Меч"
print(word:utf8len())       -- 3
print(word:utf8sub(1, 1))   -- "М"
print(word:utf8sub(2, 3))   -- "еч"
print(word:utf8sub(-1))     -- "ч"
</code>
<c>word:utf8len()</c> — это сокращённая запись для <c>string.utf8len(word)</c>.
<c>word:utf8sub(1, 1)</c> — это сокращённая запись для <c>string.utf8sub(word, 1, 1)</c>.
<h>Когда что брать</h>
<t>Латиница, цифры, GUID — <k>string.sub</k> / <k>string.len</k>.</t>
<t>Кириллица или смешанный/неизвестный текст — <k>string.utf8sub</k> / <k>string.utf8len</k>.</t>
]=],
}

ns_llua['lua'][51.3] = {
    type = "commenttest",
    title = "Тест: функция BuildPrefixes",
    helpModules = {51.1, 31, 44, 45},
    preloadVars = {
        {var = "BuildPrefixes", desc = "BuildPrefixes очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3"},
    instruction = [=[
<h>Тест: функция BuildPrefixes</h>
<t>Создай глобальную функцию <k>BuildPrefixes(word)</k>.</t>
<t>Функция должна вернуть массив нарастающих префиксов слова.</t>
<t>Используй цикл <k>for</k>, <k>string.sub</k> и <k>table.insert</k>.</t>
<t>Пример: для <s>"molot"</s> верни <c>{"m", "mo", "mol", "molo", "molot"}</c>.</t>
<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function BuildPrefixes(word)

end
]=],
    requireKeywords = {"BuildPrefixes", "function", "for", "string.utf8sub", "table.insert", "return"},
    forbidKeywords = {},
    checkCode = function()
        _G.checkError = nil
        for i = 1, 3 do _G["test" .. i] = nil end
        if type(_G.BuildPrefixes) ~= "function" then
            _G.checkError = "BuildPrefixes не является глобальной функцией"; return false
        end
        local function fmt(t)
            local p = {}
            for i = 1, #t do p[i] = '"' .. t[i] .. '"' end
            return "{" .. table.concat(p, ", ") .. "}"
        end
        local function expected(word)
            local r = {}
            for i = 1, #word do table.insert(r, string.sub(word, 1, i)) end
            return r
        end
        local tests = {{"molot"}, {"ab"}, {""}}
        for i, test in ipairs(tests) do
            local exp = expected(test[1])
            local ok, res = pcall(_G.BuildPrefixes, test[1])
            _G["test" .. i] = "Вход: \"" .. test[1] .. "\" | Получено: " .. (type(res)=="table" and fmt(res) or tostring(res)) .. " | Ожидалось: " .. fmt(exp)
            if not ok or type(res) ~= "table" or #res ~= #exp then
                _G.checkError = "Тест " .. i .. " не пройден"; return false
            end
            for j = 1, #exp do
                if res[j] ~= exp[j] then _G.checkError = "Тест " .. i .. " не пройден"; return false end
            end
        end
        return true
    end,
}

ns_llua['lua'][51.4] = {
    type = "commenttest",
    title = "Тест: функция FilterByPrefix",
    helpModules = {51.1, 31, 44, 45},
    preloadVars = {
        {var = "FilterByPrefix", desc = "FilterByPrefix очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2"},
    instruction = [=[
<h>Тест: функция FilterByPrefix</h>
<t>Создай глобальную функцию <k>FilterByPrefix(words, prefix)</k>.</t>
<t>Функция должна вернуть массив только тех слов, которые начинаются с <k>prefix</k>.</t>
<t>Пример: <c>({"sword","shield","spear"}, "sh")</c> -> <c>{"shield"}</c>.</t>
<w>string.find использовать нельзя — сравнивай префикс через string.sub.</w>
<w>Ничего выводить не нужно.</w>
<w>Бонус:</w> если код будет 201 символ или меньше, будет бонусная награда.
]=],
    initialCode = [=[
function FilterByPrefix(words, prefix)
end
]=],
    requireKeywords = {"FilterByPrefix", "function", "return"},
    forbidKeywords = {"string.find"},
    checkCode = function()
        _G.checkError = nil
        _G.test1 = nil
        _G.test2 = nil

        if type(_G.FilterByPrefix) ~= "function" then
            _G.checkError = "FilterByPrefix не является глобальной функцией"
            return false
        end

        local function fmt(t)
            local p = {}
            for i = 1, #t do
                p[i] = '"' .. t[i] .. '"'
            end
            return "{" .. table.concat(p, ", ") .. "}"
        end

        local function expected(words, prefix)
            local r = {}
            for _, w in ipairs(words) do
                if string.sub(w, 1, #prefix) == prefix then
                    table.insert(r, w)
                end
            end
            return r
        end

        local tests = {
            {words = {"sword", "shield", "spear"}, prefix = "s"},
            {words = {"sword", "shield", "spear"}, prefix = "sh"},
        }

        for i, test in ipairs(tests) do
            local exp = expected(test.words, test.prefix)
            local ok, res = pcall(_G.FilterByPrefix, test.words, test.prefix)

            _G["test" .. i] = "Получено: "
                .. (type(res) == "table" and fmt(res) or tostring(res))
                .. " | Ожидалось: "
                .. fmt(exp)

            if not ok or type(res) ~= "table" or #res ~= #exp then
                _G.checkError = "Тест " .. i .. " не пройден"
                return false
            end

            for j = 1, #exp do
                if res[j] ~= exp[j] then
                    _G.checkError = "Тест " .. i .. " не пройден"
                    return false
                end
            end
        end

        return true
    end,
}

ns_llua['lua'][51.5] = {
    type = "commenttest",
    title = "Тест: функция CountLongWords",
    helpModules = {51.2, 31, 45},
    preloadVars = {
        {var = "CountLongWords", desc = "CountLongWords очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2"},
    instruction = [=[
<h>Тест: функция CountLongWords</h>
<t>Создай глобальную функцию <k>CountLongWords(words, minLen)</k>.</t>
<t>Функция должна вернуть количество слов, у которых длина (в символах) больше или равна <k>minLen</k>.</t>
<t>Пример: <c>({"Меч","Щит","Зелье","Лук"}, 3)</c> -> <n>4</n>.</t>
<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function CountLongWords(words, minLen)

end
]=],
    requireKeywords = {"CountLongWords", "function", "for", "return"},
    forbidKeywords = {},
    checkCode = function()
        _G.checkError = nil
        _G.test1 = nil; _G.test2 = nil
        if type(_G.CountLongWords) ~= "function" then
            _G.checkError = "CountLongWords не является глобальной функцией"; return false
        end
        local function expected(words, minLen)
            local n = 0
            for _, w in ipairs(words) do
                if string.utf8len(w) >= minLen then n = n + 1 end
            end
            return n
        end
        local tests = {
            {words = {"Меч","Щит","Зелье","Лук"}, minLen = 3, exp = 4},
            {words = {"Меч","Щит","Зелье","Лук"}, minLen = 4, exp = 1},
        }
        for i, test in ipairs(tests) do
            local ok, res = pcall(_G.CountLongWords, test.words, test.minLen)
            _G["test" .. i] = "Получено: " .. tostring(res) .. " | Ожидалось: " .. test.exp
            if not ok or res ~= test.exp then
                _G.checkError = "Тест " .. i .. " не пройден"; return false
            end
        end
        return true
    end,
}

ns_llua['lua'][51.6] = {
    type = "commenttest",
    title = "Тест: функция SplitChars",
    helpModules = {51.2, 31, 44, 45},
    preloadVars = {
        {var = "SplitChars", desc = "SplitChars очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2"},
    instruction = [=[
<h>Тест: функция SplitChars</h>
<t>Создай глобальную функцию <k>SplitChars(word)</k>.</t>
<t>Функция должна вернуть массив отдельных символов слова.</t>
<t>Используй <k>string.utf8len</k> для длины и <k>string.utf8sub(word, i, i)</k> для символа.</t>
<t>Пример: для <s>"Меч"</s> верни <c>{"М", "е", "ч"}</c>.</t>
<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function SplitChars(word)

end
]=],
    requireKeywords = {"SplitChars", "function", "for", "return"},
    forbidKeywords = {},
    checkCode = function()
        _G.checkError = nil
        _G.test1 = nil; _G.test2 = nil
        if type(_G.SplitChars) ~= "function" then
            _G.checkError = "SplitChars не является глобальной функцией"; return false
        end
        local function fmt(t)
            local p = {}
            for i = 1, #t do p[i] = '"' .. t[i] .. '"' end
            return "{" .. table.concat(p, ", ") .. "}"
        end
        local function expected(word)
            local r = {}
            for i = 1, string.utf8len(word) do
                table.insert(r, string.utf8sub(word, i, i))
            end
            return r
        end
        local tests = {{"Меч"}, {"sword"}}
        for i, test in ipairs(tests) do
            local exp = expected(test[1])
            local ok, res = pcall(_G.SplitChars, test[1])
            _G["test" .. i] = "Вход: \"" .. test[1] .. "\" | Получено: " .. (type(res)=="table" and fmt(res) or tostring(res)) .. " | Ожидалось: " .. fmt(exp)
            if not ok or type(res) ~= "table" or #res ~= #exp then
                _G.checkError = "Тест " .. i .. " не пройден"; return false
            end
            for j = 1, #exp do
                if res[j] ~= exp[j] then _G.checkError = "Тест " .. i .. " не пройден"; return false end
            end
        end
        return true
    end,
}

ns_llua['lua'][51.7] = {
    type = "commenttest",
    title = "Тест: функция CountChars",
    helpModules = {51.2, 31, 44, 45},
    preloadVars = {
        {var = "CountChars", desc = "CountChars очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2"},
    instruction = [=[
<h>Тест: функция CountChars</h>
<t>Создай глобальную функцию <k>CountChars(word)</k>.</t>
<t>Функция должна вернуть хэш-таблицу: символ -> сколько раз он встречается.</t>
<t>Используй <k>string.utf8len</k>, <k>string.utf8sub</k> и накопление в таблице.</t>
<t>Пример: для <s>"абба"</s> верни <c>{["а"]=2, ["б"]=2}</c>.</t>
<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function CountChars(word)

end
]=],
    requireKeywords = {"CountChars", "function", "for", "return"},
    forbidKeywords = {},
    checkCode = function()
        _G.checkError = nil
        _G.test1 = nil; _G.test2 = nil
        if type(_G.CountChars) ~= "function" then
            _G.checkError = "CountChars не является глобальной функцией"; return false
        end
        local function expected(word)
            local r = {}
            for i = 1, string.utf8len(word) do
                local ch = string.utf8sub(word, i, i)
                r[ch] = (r[ch] or 0) + 1
            end
            return r
        end
        local function fmtMap(t)
            local keys = {}
            for k in pairs(t) do table.insert(keys, k) end
            table.sort(keys)
            local p = {}
            for _, k in ipairs(keys) do table.insert(p, k .. "=" .. t[k]) end
            return "{" .. table.concat(p, ", ") .. "}"
        end
        local function same(a, b)
            for k, v in pairs(a) do if b[k] ~= v then return false end end
            for k in pairs(b) do if a[k] == nil then return false end end
            return true
        end
        local tests = {{"абба"}, {"Меч"}}
        for i, test in ipairs(tests) do
            local exp = expected(test[1])
            local ok, res = pcall(_G.CountChars, test[1])
            _G["test" .. i] = "Вход: \"" .. test[1] .. "\" | Получено: " .. (type(res)=="table" and fmtMap(res) or tostring(res)) .. " | Ожидалось: " .. fmtMap(exp)
            if not ok or type(res) ~= "table" or not same(res, exp) then
                _G.checkError = "Тест " .. i .. " не пройден"; return false
            end
        end
        return true
    end,
}

ns_llua['lua'][52] = {
    type = "commenttest",
    title = "Итоговый комбо-тест: функция calculateTotalPrice",
    helpModules = {44, 45, 31, 10},
    preloadVars = {
        {var = "calculateTotalPrice", desc = "calculateTotalPrice очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
    },
    instruction = [=[
<h>Практика: функция calculateTotalPrice</h>
<t>Создай глобальную функцию <k>calculateTotalPrice(priceList, cart)</k>.</t>
<t><k>priceList</k> — таблица цен (ключ = название, значение = цена числом или строкой).</t>
<t><k>cart</k> — массив названий выбранных предметов.</t>
<t>Функция возвращает общую стоимость корзины.</t>
<t>Предмета нет в <k>priceList</k> — не считай его.</t>
<t>Цена строкой — преобразуй через <k>tonumber</k>.</t>
<t><k>tonumber</k> дал <k>nil</k> — не считай эту цену.</t>
<t>Таблицы создавать не надо — система подставит свои и покажет результат в отчёте.</t>
]=],
    initialCode = [=[
-- Создай глобальную функцию calculateTotalPrice(priceList, cart)
]=],
    requireKeywords = {
        "calculateTotalPrice",
        "function",
        "for",
        "tonumber",
        "return",
    },
    checkCode = function()
        local function isArray(t)
            local n = #t
            if n == 0 then
                for _ in pairs(t) do
                    return false
                end
                return true
            end

            local count = 0
            for k in pairs(t) do
                count = count + 1
                if type(k) ~= "number" or k < 1 or k > n or k ~= math.floor(k) then
                    return false
                end
            end

            return count == n
        end

        local function fmt(v, depth)
            depth = depth or 0
            local t = type(v)

            if t == "string" then
                return '"' .. v .. '"'
            elseif t == "number" or t == "boolean" then
                return tostring(v)
            elseif t == "nil" then
                return "nil"
            elseif t == "table" then
                if depth >= 2 then
                    return "{...}"
                end

                if isArray(v) then
                    local parts = {}
                    for i = 1, #v do
                        parts[i] = fmt(v[i], depth + 1)
                    end
                    return "{" .. table.concat(parts, ", ") .. "}"
                end

                local keys = {}
                for k in pairs(v) do
                    table.insert(keys, k)
                end
                table.sort(keys, function(a, b)
                    return tostring(a) < tostring(b)
                end)

                local parts = {}
                for _, k in ipairs(keys) do
                    local ks
                    if type(k) == "string" then
                        ks = '["' .. k .. '"]'
                    else
                        ks = "[" .. tostring(k) .. "]"
                    end
                    table.insert(parts, ks .. "=" .. fmt(v[k], depth + 1))
                end

                return "{" .. table.concat(parts, ", ") .. "}"
            end

            return "<" .. t .. ">"
        end

        _G.checkError = nil
        _G.test1 = nil
        _G.test2 = nil
        _G.test3 = nil
        _G.test4 = nil

        if type(_G.calculateTotalPrice) ~= "function" then
            _G.checkError = "calculateTotalPrice не является глобальной функцией"
            return false
        end

        local tests = {
            {
                input = {{["X"] = "5", ["Y"] = 7, ["Z"] = "bad"}, {"X", "Y", "Z", "W"}},
                expected = 12,
            },
            {
                input = {{}, {"A"}},
                expected = 0,
            },
            {
                input = {{["A"] = "10"}, {}},
                expected = 0,
            },
            {
                input = {{["A"] = "abc"}, {"A"}},
                expected = 0,
            },
        }

        local allOk = true

        for i, test in ipairs(tests) do
            local inputText = fmt(test.input[1]) .. ", " .. fmt(test.input[2])
            local ok, result = pcall(_G.calculateTotalPrice, test.input[1], test.input[2])

            local resultText
            if ok then
                resultText = fmt(result)
            else
                resultText = "ошибка: " .. tostring(result)
            end

            _G["test" .. i] = "Аргументы: "
                .. inputText
                .. " | Результат: "
                .. resultText
                .. " | Ожидалось: "
                .. fmt(test.expected)

            if not ok or result ~= test.expected then
                allOk = false
            end
        end

        return allOk
    end,
}

ns_llua['lua'][52.1] = {
    type = "commenttest",
    title = "Итоговый комбо-тест: таблицы, insert, remove, sort и concat",
    helpModules = {29.1, 31.1, 31.2, 44.1, 52},
    preloadVars = {
        {var = "finalCart", desc = "finalCart очищается перед проверкой"},
        {var = "finalCartCount", desc = "finalCartCount очищается перед проверкой"},
        {var = "finalCartText", desc = "finalCartText очищается перед проверкой"},
    },
    reportVars = {"finalCart", "finalCartCount", "finalCartText"},
    instruction = [=[
<h>Итоговый комбо-тест: таблицы</h>
<t>Создай глобальную таблицу <k>finalCart</k>.</t>

<t>Порядок действий:</t>
<t>1. Добавь четыре предмета:</t>
<s>"Меч", "Зелье", "Щит", "Факел"</s>

<t>2. Удали третий элемент.</t>

<t>3. Добавь в конец предмет <s>"Компас"</s>.</t>

<t>4. Отсортируй таблицу <k>finalCart</k>.</t>

<t>5. Создай глобальную переменную <k>finalCartCount</k> с количеством элементов в корзине.</t>

<t>6. Собери все текущие элементы корзины в одну строку с разделителем из запятой и пробела и сохрани результат в глобальную переменную <k>finalCartText</k>.</t>

<t>Ожидаемый результат после сортировки:</t>
<code>
finalCart = {"Зелье", "Компас", "Меч", "Факел"}
finalCartCount = 4
finalCartText = "Зелье, Компас, Меч, Факел"
</code>

<t>Ничего выводить не нужно.</t>
<w>Не используй <k>local</k>, переменные нужны глобальные.</w>
]=],
    initialCode = [=[
-- Создай finalCart и выполни все операции
]=],
    requireKeywords = {
        "finalCart",
        "finalCartCount",
        "finalCartText",
        "table.insert",
        "table.remove",
        "table.sort",
        "table.concat",
        "3",
        "#",
        "finalCartText=table.concat(finalCart",
    },
    forbidKeywords = {
        "finalCartCount=4",
        'finalCartText="Зелье,Компас,Меч,Факел"',
        "finalCartText='Зелье,Компас,Меч,Факел'",
    },
    checkCode = function()
        return type(_G.finalCart) == "table"
            and #_G.finalCart == 4
            and _G.finalCart[1] == "Зелье"
            and _G.finalCart[2] == "Компас"
            and _G.finalCart[3] == "Меч"
            and _G.finalCart[4] == "Факел"
            and _G.finalCartCount == 4
            and _G.finalCartText == "Зелье, Компас, Меч, Факел"
    end,
}

-- ============================================================
-- COURSE DATA: MODULES 52.2-52.9
-- LOOKUP-TABLES: DATA DRIVEN FUNCTIONS
-- Без WoW API, только абстрактные учебные примеры
-- ============================================================

ns_llua['lua'][52.2] = {
    type = "info",
    title = "Данные отдельно: lookup-таблицы, наборы и значения",
    content = [=[
<h>Данные отдельно: lookup-таблицы</h>
<t>Lookup-таблица — это обычная таблица, в которой данные хранятся как пары <k>ключ = значение</k>. Вместо того чтобы писать длинную цепочку if/elseif, программа просто достаёт значение по ключу.</t>

<h>Проблема: данные размазаны по логике</h>
<t>Часто новички пишут так:</t>
<code>
function GetFruitName(token)
    if token == "APPLE" then
        return "яблоко"
    elseif token == "BANANA" then
        return "банан"
    elseif token == "CHERRY" then
        return "вишня"
    elseif token == "MELON" then
        return "арбуз"
    end
end
</code>
<t>Работает, но минусы такие:</t>
<t>- данные и логика смешаны;</t>
<t>- при добавлении нового значения нужно снова лезть в функцию;</t>
<t>- легко сделать опечатку в условиях;</t>
<t>- код становится длиннее и хуже читается.</t>

<h>Решение: вынести данные в таблицу</h>
<code>
FRUIT_NAMES = {
    APPLE = "яблоко",
    BANANA = "банан",
    CHERRY = "вишня",
    MELON = "арбуз",
}

function GetFruitName(token)
    -- Сначала проверяем token: если он nil или false, дальше не идём и вернём "неизвестно".
    -- Если token нормальный, пробуем достать значение из таблицы: FRUIT_NAMES[token].
    -- Если такого ключа нет, получится nil, и тогда or вернёт "неизвестно".
    return token and FRUIT_NAMES[token] or "неизвестно"
end
</code>
<t>Теперь функция универсальная и короткая. Она не знает заранее, какие именно значения существуют. Она просто знает, что нужно взять значение из таблицы по ключу.</t>

<h>Как это работает</h>
<t>Запись <k>FRUIT_NAMES[token]</k> означает:</t>
<t>- возьми таблицу <k>FRUIT_NAMES</k>;</t>
<t>- найди в ней ключ <k>token</k>;</t>
<t>- верни значение по этому ключу.</t>
<code>
FRUIT_NAMES = {
    APPLE = "яблоко",
}

print(FRUIT_NAMES["APPLE"]) -- яблоко
print(FRUIT_NAMES["FURY"])  -- nil
</code>

<h>Таблица-набор: есть или нет</h>
<t>Если нужно просто проверять, входит ли элемент в набор, таблицу используют как набор. В такой таблице ключ означает сам элемент, а значение просто говорит: «ключ существует».</t>
<t>Самый понятный маркер для такого набора — <k>true</k>.</t>
<code>
MODERATORS = {
    ["Шеф"] = true,
    ["Высшая"] = true,
}

-- Если ключ есть, вернётся true.
-- Если ключа нет, вернётся nil, а nil считается ложью.
if MODERATORS["Шеф"] then
    print("Это модератор")
end
</code>

<h>Безопасная проверка с именем</h>
<t>Если имя может быть <k>nil</k>, сначала нужно проверить его, иначе обращение к таблице по nil-ключу даст ошибку.</t>
<code>
local name = "Шеф"

if name and MODERATORS[name] then
    print("Это модератор")
end
</code>
<t>Или через функцию:</t>
<code>
function IsModerator(name)
    -- Если name равен nil или false, сразу вернём false.
    -- Если name есть в таблице, MODERATORS[name] вернёт true.
    -- Если ключа нет, получится nil, и or заменит его на false.
    return name and MODERATORS[name] or false
end
</code>

<h>Почему массив не заменяет такой набор</h>
<t>Иногда хочется написать так:</t>
<code>
BAD_MODERATORS = {
    "Шеф",
    "Высшая",
}

if BAD_MODERATORS["Шеф"] then
    print("Это модератор")
end
</code>
<w>Так работать не будет.</w>
<t>Это массив. Его ключи — числа 1, 2 и так далее. Запись <k>BAD_MODERATORS["Шеф"]</k> ищет строковый ключ <s>"Шеф"</s>, а его там нет, поэтому вернётся <k>nil</k>.</t>
<code>
print(BAD_MODERATORS["Шеф"]) -- nil
print(BAD_MODERATORS[1])     -- Шеф
</code>
<t>То есть массив хранит значения по номерам. Он не возвращает <k>true</k> автоматически только потому, что элемент где-то есть внутри.</t>
<t>Если нужно проверить вхождение элемента в массив, придётся либо идти циклом по массиву, либо заранее превратить его в таблицу-набор.</t>

<h>Вариант с разными значениями</h>
<t>Теперь представим, что таблица хранит не просто признак «есть», а конкретные данные. Например, роли игроков.</t>
<code>
USER_ROLES = {
    ["Шеф"] = "admin",
    ["Высшая"] = "moderator",
    ["Гость"] = "viewer",
}
</code>
<t>Здесь значения уже разные и имеют смысл:</t>
<t>- <s>"admin"</s> — администратор;</t>
<t>- <s>"moderator"</s> — модератор;</t>
<t>- <s>"viewer"</s> — обычный зритель.</t>

<h>Почему простого условия уже недостаточно</h>
<t>Если написать так:</t>
<code>
if USER_ROLES["Гость"] then
    print("У игрока есть роль")
end
</code>
<t>условие сработает, потому что ключ <s>"Гость"</s> есть в таблице, а значение <s>"viewer"</s> в Lua считается истиной.</t>
<t>Но такая проверка говорит только: «игрок есть в таблице». Она не говорит, что у него нужные права.</t>
<t>Если нужно проверить конкретную роль, надо сравнивать значение:</t>
<code>
if USER_ROLES["Шеф"] == "admin" then
    print("Это админ")
end
</code>
<t>Если нужно проверить несколько ролей, можно сохранить значение в переменную:</t>
<code>
local role = USER_ROLES["Высшая"]

if role == "admin" or role == "moderator" then
    print("Есть права модератора")
end
</code>

<h>Функция для точной проверки значения</h>
<code>
function IsAdmin(name)
    -- Если name равен nil или false, сразу вернём false.
    -- Иначе достаём роль из таблицы и сравниваем её с нужным значением.
    return name ~= nil and USER_ROLES[name] == "admin"
end

function IsModeratorRole(name)
    -- Достаём роль игрока из таблицы.
    local role = USER_ROLES[name]

    -- Если роль nil, сравнения просто дадут false.
    return role == "admin" or role == "moderator"
end
</code>
<t>Здесь уже важно сравнивать именно значение, потому что наличие ключа само по себе ничего не говорит о правах игрока.</t>

<h>Почему в первом случае хватает простого условия</h>
<t>В первом случае таблица — это набор. Ключ есть — значит «да». Ключа нет — значит «нет».</t>
<c>ключ найден -> значение истинное -> условие проходит;</c>
<c>ключ не найден -> nil -> условие не проходит.</c>
<t>Поэтому достаточно короткой проверки:</t>
<code>
if MODERATORS[name] then
    print("Входит в набор")
end
</code>

<h>Почему во втором случае нужно уточнять</h>
<t>Во втором случае таблица — это словарь данных. Разные значения означают разные состояния или права. Само наличие ключа уже не означает нужное право.</t>
<t>Поэтому нужно проверять не просто «ключ есть», а «ключ есть и значение именно такое, какое нужно».</t>
<code>
if USER_ROLES[name] == "admin" then
    print("Это админ")
end
</code>

<h>Итоговая шпаргалка</h>
<c>Таблица-набор: ключ есть = да, ключа нет = нет.</c>
<c>Для набора удобно использовать значение true.</c>
<c>В наборе обычно достаточно: if set[name] then.</c>
<c>Если key может быть nil, безопаснее: if name and set[name] then.</c>
<c>Массив не проверяет наличие элемента по значению через arr[value].</c>
<c>Таблица-словарь: значения имеют смысл.</c>
<c>В словаре нужно сравнивать значение: if map[name] == expected then.</c>
]=],
}

ns_llua['lua'][52.3] = {
    type = "commenttest",
    title = "Практика: карта значений",
    helpModules = {52.2, 44, 45, 21.1},
    preloadVars = {
        {var = "colorNames", desc = "colorNames очищается перед проверкой"},
        {var = "GetColorName", desc = "GetColorName очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
        {var = "test5", desc = "test5 очищается перед проверкой"},
        {var = "test6", desc = "test6 очищается перед проверкой"},
        {var = "test7", desc = "test7 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
        "test5",
        "test6",
        "test7",
    },
    instruction = [=[
<h>Практика: карта значений</h>
<t>Создай глобальную таблицу <k>colorNames</k> с такими парами:</t>
<code>
RED - красный
GREEN - зелёный
BLUE - синий
YELLOW - жёлтый
</code>
<t>Создай глобальную функцию <k>GetColorName(token)</k>.</t>
<t>Функция должна возвращать значение из <k>colorNames</k> по ключу <k>token</k>.</t>
<t>Если token равен nil или такого ключа нет, функция должна вернуть <s>"неизвестно"</s>.</t>
<t>Смысл возврата такой:</t>
<c>Если token существует и есть в таблице, вернём colorNames[token].</c>
<c>Если token ложный или ключ не найден, вернём "неизвестно".</c>
]=],
    initialCode = [=[
colorNames = {

}

function GetColorName(token)
    
end
]=],
    requireKeywords = {
        "colorNames",
        "GetColorName",
        "function",
        "return",
        "RED",
        "GREEN",
        "BLUE",
        "YELLOW",
    },
    checkCode = function()
        local details = {}

        _G.checkError = nil

        for i = 1, 7 do
            _G["test" .. i] = nil
        end

        local function fmt(value)
            if type(value) == "string" then
                return '"' .. value .. '"'
            end

            return tostring(value)
        end

        if type(_G.colorNames) ~= "table" then
            _G.checkError = "colorNames должна быть глобальной таблицей"
            return _G.checkError
        end

        local expectedMap = {
            RED = "красный",
            GREEN = "зелёный",
            BLUE = "синий",
            YELLOW = "жёлтый",
        }

        for key, expected in pairs(expectedMap) do
            if _G.colorNames[key] ~= expected then
                _G.checkError = "В colorNames неправильное значение для ключа " .. tostring(key)
                return _G.checkError
            end
        end

        if type(_G.GetColorName) ~= "function" then
            _G.checkError = "GetColorName должна быть глобальной функцией"
            return _G.checkError
        end

        local tests = {
            {arg = "RED", expected = "красный"},
            {arg = "GREEN", expected = "зелёный"},
            {arg = "BLUE", expected = "синий"},
            {arg = "YELLOW", expected = "жёлтый"},
            {arg = "UNKNOWN", expected = "неизвестно"},
            {arg = "", expected = "неизвестно"},
            {arg = nil, expected = "неизвестно"},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(_G.GetColorName, test.arg)

            local resultText
            if ok then
                resultText = fmt(result)
            else
                resultText = "ошибка: " .. tostring(result)
            end

            local line = string.format(
                "Вход: %s | Получено: %s | Ожидалось: %s",
                fmt(test.arg),
                resultText,
                fmt(test.expected)
            )

            _G["test" .. i] = line

            if not ok or result ~= test.expected then
                table.insert(details, line)
            end
        end

        if #details > 0 then
            _G.checkError = "Проверка результата не пройдена"
            return table.concat(details, "\n")
        end

        return true
    end,
}

ns_llua['lua'][52.4] = {
    type = "commenttest",
    title = "Практика: таблица-множество модераторов",
    helpModules = {52.2, 44, 45, 15},
    preloadVars = {
        {var = "moderators", desc = "moderators очищается перед проверкой"},
        {var = "IsModerator", desc = "IsModerator очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
        {var = "test5", desc = "test5 очищается перед проверкой"},
        {var = "test6", desc = "test6 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
        "test5",
        "test6",
    },
    instruction = [=[
<h>Практика: таблица-множество модераторов</h>
<t>Создай глобальную таблицу <k>moderators</k>.</t>
<t>Ключи — имена модераторов, значения — <k>true</k>:</t>
<code>
Артас
Джайна
Тралл
</code>
<t>Создай глобальную функцию <k>IsModerator(name)</k>.</t>
<t>Функция должна вернуть <k>true</k>, если name есть в таблице <k>moderators</k>, и <k>false</k> во всех остальных случаях.</t>
<t>Если name равен nil, функция должна вернуть <k>false</k>, а не ошибку.</t>
]=],
    initialCode = [=[
moderators = {

}

function IsModerator(name)

end
]=],
    requireKeywords = {
        "moderators",
        "IsModerator",
        "function",
        "return",
        "true",
        "Артас",
        "Джайна",
        "Тралл",
    },
    checkCode = function()
        local details = {}

        _G.checkError = nil

        for i = 1, 6 do
            _G["test" .. i] = nil
        end

        local function fmt(value)
            if type(value) == "string" then
                return '"' .. value .. '"'
            end

            return tostring(value)
        end

        if type(_G.moderators) ~= "table" then
            _G.checkError = "moderators должна быть глобальной таблицей"
            return _G.checkError
        end

        local names = {"Артас", "Джайна", "Тралл"}

        for _, name in ipairs(names) do
            if _G.moderators[name] ~= true then
                _G.checkError = "В moderators должен быть ключ " .. name .. " со значением true"
                return _G.checkError
            end
        end

        if type(_G.IsModerator) ~= "function" then
            _G.checkError = "IsModerator должна быть глобальной функцией"
            return _G.checkError
        end

        local tests = {
            {arg = "Артас", expected = true},
            {arg = "Джайна", expected = true},
            {arg = "Тралл", expected = true},
            {arg = "Иллидан", expected = false},
            {arg = "", expected = false},
            {arg = nil, expected = false},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(_G.IsModerator, test.arg)

            local resultText
            if ok then
                resultText = fmt(result)
            else
                resultText = "ошибка: " .. tostring(result)
            end

            local line = string.format(
                "Вход: %s | Получено: %s | Ожидалось: %s",
                fmt(test.arg),
                resultText,
                fmt(test.expected)
            )

            _G["test" .. i] = line

            if not ok or result ~= test.expected then
                table.insert(details, line)
            end
        end

        if #details > 0 then
            _G.checkError = "Проверка результата не пройдена"
            return table.concat(details, "\n")
        end

        return true
    end,
}

ns_llua['lua'][52.5] = {
    type = "commenttest",
    title = "Практика: универсальная проверка вхождения",
    helpModules = {52.2, 52.4, 44, 45},
    preloadVars = {
        {var = "blockedPlayers", desc = "blockedPlayers очищается перед проверкой"},
        {var = "trustedPlayers", desc = "trustedPlayers очищается перед проверкой"},
        {var = "IsInSet", desc = "IsInSet очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
        {var = "test5", desc = "test5 очищается перед проверкой"},
        {var = "test6", desc = "test6 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
        "test5",
        "test6",
    },
    instruction = [=[
<h>Практика: универсальная проверка вхождения</h>
<t>В этом задании мы делаем проверку на разрешённых и заблокированных пользователей.</t>

<t>Создай глобальную таблицу <k>blockedPlayers</k>.</t>
<t>Это чёрный список: добавь в него заблокированных игроков <s>"Гулдан"</s> и <s>"КелТузад"</s>. В качестве значения используй <k>true</k>.</t>

<t>Создай глобальную таблицу <k>trustedPlayers</k>.</t>
<t>Это белый список: добавь в него разрешённых игроков <s>"Артас"</s> и <s>"Джайна"</s>. В качестве значения используй <k>true</k>.</t>

<t>Создай глобальную функцию <k>IsInSet(set, name)</k>.</t>
<t>Функция должна быть универсальной: она принимает любую таблицу-множество и имя, а затем проверяет, входит ли это имя в таблицу.</t>
<t>Такую функцию можно использовать и для списка заблокированных, и для списка разрешённых пользователей.</t>

<t>Если set не является таблицей или name равен nil, функция должна вернуть <k>false</k>.</t>
<t>Иначе функция должна вернуть <k>true</k> только если <k>set[name] == true</k>.</t>
]=],
    initialCode = [=[
blockedPlayers = {

}

trustedPlayers = {

}

function IsInSet(set, name)

end
]=],
    requireKeywords = {
        "blockedPlayers",
        "trustedPlayers",
        "IsInSet",
        "function",
        "return",
        "true",
    },
    checkCode = function()
        local details = {}

        _G.checkError = nil

        for i = 1, 6 do
            _G["test" .. i] = nil
        end

        local function fmt(value)
            if type(value) == "string" then
                return '"' .. value .. '"'
            end

            return tostring(value)
        end

        if type(_G.blockedPlayers) ~= "table" then
            _G.checkError = "blockedPlayers должна быть глобальной таблицей"
            return _G.checkError
        end

        if type(_G.trustedPlayers) ~= "table" then
            _G.checkError = "trustedPlayers должна быть глобальной таблицей"
            return _G.checkError
        end

        local blockedNames = {"Гулдан", "КелТузад"}

        for _, name in ipairs(blockedNames) do
            if _G.blockedPlayers[name] ~= true then
                _G.checkError = "В blockedPlayers должен быть ключ " .. name .. " со значением true"
                return _G.checkError
            end
        end

        local trustedNames = {"Артас", "Джайна"}

        for _, name in ipairs(trustedNames) do
            if _G.trustedPlayers[name] ~= true then
                _G.checkError = "В trustedPlayers должен быть ключ " .. name .. " со значением true"
                return _G.checkError
            end
        end

        if type(_G.IsInSet) ~= "function" then
            _G.checkError = "IsInSet должна быть глобальной функцией"
            return _G.checkError
        end

        local tests = {
            {set = _G.blockedPlayers, setName = "blockedPlayers", name = "Гулдан", expected = true},
            {set = _G.blockedPlayers, setName = "blockedPlayers", name = "Артас", expected = false},
            {set = _G.trustedPlayers, setName = "trustedPlayers", name = "Артас", expected = true},
            {set = _G.trustedPlayers, setName = "trustedPlayers", name = "Гулдан", expected = false},
            {set = nil, setName = "nil", name = "Артас", expected = false},
            {set = _G.blockedPlayers, setName = "blockedPlayers", name = nil, expected = false},
        }

        local allOk = true

        for i, test in ipairs(tests) do
            local ok, result = pcall(_G.IsInSet, test.set, test.name)

            local resultText
            if ok then
                resultText = fmt(result)
            else
                resultText = "ошибка: " .. tostring(result)
            end

            local line = string.format(
                "Вход: %s, %s | Получено: %s | Ожидалось: %s",
                test.setName,
                fmt(test.name),
                resultText,
                fmt(test.expected)
            )

            _G["test" .. i] = line

            if not ok or result ~= test.expected then
                allOk = false
                table.insert(details, line)
            end
        end

        if not allOk then
            _G.checkError = "Проверка результата не пройдена"
            return table.concat(details, "\n")
        end

        return true
    end,
}

ns_llua['lua'][52.6] = {
    type = "commenttest",
    title = "Практика: lookup с числовыми ключами ",
    helpModules = {52.2, 44, 45, 10},
    preloadVars = {
        {var = "discountByRank", desc = "discountByRank очищается перед проверкой"},
        {var = "GetDiscount", desc = "GetDiscount очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
        {var = "test5", desc = "test5 очищается перед проверкой"},
        {var = "test6", desc = "test6 очищается перед проверкой"},
        {var = "test7", desc = "test7 очищается перед проверкой"},
        {var = "test8", desc = "test8 очищается перед проверкой"},
        {var = "test9", desc = "test9 очищается перед проверкой"},
        {var = "test10", desc = "test10 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
        "test5",
        "test6",
        "test7",
        "test8",
        "test9",
        "test10",
    },
    instruction = [=[
<h>Практика: lookup с числовыми ключами</h>
<t>Это пример таблицы, где по номеру ранга хранится размер скидки.</t>

<h>Шаг 1: таблица скидок</h>
<t>Создай глобальную таблицу <k>discountByRank</k> со значениями:</t>
<code>
0
5
10
15
</code>
<t>То есть:</t>
<c>ранг 1 -> скидка 0</c>
<c>ранг 2 -> скидка 5</c>
<c>ранг 3 -> скидка 10</c>
<c>ранг 4 -> скидка 15</c>

<h>Шаг 2: функция GetDiscount(rank)</h>
<t>Создай глобальную функцию <k>GetDiscount(rank)</k>. Она должна вернуть размер скидки для ранга <k>rank</k>.</t>

<h>Что должна делать функция</h>
<c>1. Достань значение из discountByRank по значению rank.</c>
<c>2. Если что то пошло не так — верни 0.</c>

<h>Зачем это нужно</h>
<t>Данные о скидках лежат в таблице отдельно. Функция не хранит кучу условий внутри себя, а просто достаёт нужное значение по ключу.</t>

]=],
    initialCode = [=[
discountByRank = {

}

function GetDiscount(rank)

end
]=],
    requireKeywords = {
        "discountByRank",
        "GetDiscount",
        "function",
        "return",
    },
    checkCode = function()
        local details = {}

        _G.checkError = nil

        for i = 1, 10 do
            _G["test" .. i] = nil
        end

        local function fmt(value)
            if type(value) == "string" then
                return '"' .. value .. '"'
            end

            return tostring(value)
        end

        if type(_G.discountByRank) ~= "table" then
            _G.checkError = "discountByRank должна быть глобальной таблицей"
            return _G.checkError
        end

        local expectedMap = {
            [1] = 0,
            [2] = 5,
            [3] = 10,
            [4] = 15,
        }

        for rank, expected in pairs(expectedMap) do
            if _G.discountByRank[rank] ~= expected then
                _G.checkError = "В discountByRank неправильное значение для ранга " .. tostring(rank)
                return _G.checkError
            end
        end

        if type(_G.GetDiscount) ~= "function" then
            _G.checkError = "GetDiscount должна быть глобальной функцией"
            return _G.checkError
        end

        local tests = {
            {arg = 1, expected = 0},
            {arg = 2, expected = 5},
            {arg = 3, expected = 10},
            {arg = 4, expected = 15},
            {arg = "2", expected = 5},
            {arg = "3", expected = 10},
            {arg = 5, expected = 0},
            {arg = "5", expected = 0},
            {arg = "bad", expected = 0},
            {arg = nil, expected = 0},
        }

        local allOk = true

        for i, test in ipairs(tests) do
            local ok, result = pcall(_G.GetDiscount, test.arg)

            local resultText
            if ok then
                resultText = fmt(result)
            else
                resultText = "ошибка: " .. tostring(result)
            end

            local line = string.format(
                "Вход: %s | Получено: %s | Ожидалось: %s",
                fmt(test.arg),
                resultText,
                fmt(test.expected)
            )

            _G["test" .. i] = line

            if not ok or result ~= test.expected then
                allOk = false
                table.insert(details, line)
            end
        end

        if not allOk then
            _G.checkError = "Проверка результата не пройдена"
            return table.concat(details, "\n")
        end

        return true
    end,
}

ns_llua['lua'][52.7] = {
    type = "commenttest",
    title = "Практика: замена элементов списка через таблицу",
    helpModules = {52.2, 31, 29.1, 45},
    preloadVars = {
        {var = "TranslateList", desc = "TranslateList очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
        {var = "test5", desc = "test5 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
        "test5",
    },
    instruction = [=[
<h>Практика: замена элементов списка через таблицу</h>
<t>Создай глобальную функцию <k>TranslateList(list, map, default)</k>.</t>

<t>Функция получает три аргумента:</t>
<c>list — массив ключей;</c>
<c>map — таблица соответствий ключ -> значение;</c>
<c>default — запасное значение.</c>

<t>Что должна сделать функция:</t>
<c>1. Пройти по всем элементам list.</c>
<c>2. Использовать каждый элемент list как ключ для map.</c>
<c>3. Если по этому ключу в map есть значение, положить его в результат.</c>
<c>4. Если значения нет, положить default.</c>
<c>5. Вернуть новый массив-результат.</c>

<w>Важно:</w>
<t>Ключом является сам элемент из list, а не его номер.</t>

<t>Дополнительные условия:</t>
<c>Если list не является таблицей, верни пустую таблицу.</c>
<c>Если map не является таблицей, считай, что значений нет, и подставляй default.</c>
<c>Исходный list менять нельзя.</c>

<w>Бонус:</w> если в решении будет 200 символов или меньше, будет бонусная награда.
]=],
    initialCode = [=[
function TranslateList(list, map, default)

end
]=],
    requireKeywords = {
        "TranslateList",
        "function",
        "return",
    },
    checkCode = function()
        local details = {}

        _G.checkError = nil

        for i = 1, 5 do
            _G["test" .. i] = nil
        end

        if type(_G.TranslateList) ~= "function" then
            _G.checkError = "TranslateList должна быть глобальной функцией"
            return _G.checkError
        end

        local function sameArrays(a, b)
            if type(a) ~= "table" or type(b) ~= "table" then
                return false
            end

            if #a ~= #b then
                return false
            end

            for i = 1, #a do
                if a[i] ~= b[i] then
                    return false
                end
            end

            return true
        end

        local function fmtScalar(value)
            if type(value) == "string" then
                return '"' .. value .. '"'
            end

            return tostring(value)
        end

        local function fmtArray(t)
            if type(t) ~= "table" then
                return tostring(t)
            end

            local parts = {}

            for i = 1, #t do
                parts[i] = fmtScalar(t[i])
            end

            return "{" .. table.concat(parts, ", ") .. "}"
        end

        local function fmtMap(t)
            if type(t) ~= "table" then
                return tostring(t)
            end

            local keys = {}

            for k in pairs(t) do
                table.insert(keys, k)
            end

            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b)
            end)

            local parts = {}

            for _, k in ipairs(keys) do
                table.insert(parts, tostring(k) .. "=" .. fmtScalar(t[k]))
            end

            return "{" .. table.concat(parts, ", ") .. "}"
        end

        local tests = {
            {
                name = "обычная замена",
                list = {"APPLE", "BANANA", "UNKNOWN"},
                map = {APPLE = "яблоко", BANANA = "банан"},
                default = "?",
                expected = {"яблоко", "банан", "?"},
            },
            {
                name = "пустой список",
                list = {},
                map = {A = 1},
                default = "?",
                expected = {},
            },
            {
                name = "list не таблица",
                list = nil,
                map = {A = 1},
                default = "?",
                expected = {},
            },
            {
                name = "map не таблица",
                list = {"A", "B"},
                map = nil,
                default = "d",
                expected = {"d", "d"},
            },
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(_G.TranslateList, test.list, test.map, test.default)

            local resultText
            if ok then
                resultText = fmtArray(result)
            else
                resultText = "ошибка: " .. tostring(result)
            end

            local line = string.format(
                "%s | Вход: list=%s, map=%s, default=%s | Получено: %s | Ожидалось: %s",
                test.name,
                fmtArray(test.list),
                fmtMap(test.map),
                fmtScalar(test.default),
                resultText,
                fmtArray(test.expected)
            )

            _G["test" .. i] = line

            if not ok or not sameArrays(result, test.expected) then
                table.insert(details, line)
            end
        end

        local original = {"APPLE"}
        local map = {APPLE = "яблоко"}
        local ok, result = pcall(_G.TranslateList, original, map, "?")

        if ok then
            _G.test5 = 'Проверка исходного list | Вход: list={"APPLE"} | Получено: '
                .. fmtArray(original)
                .. ' | Ожидалось: {"APPLE"}'

            if #original ~= 1 or original[1] ~= "APPLE" then
                table.insert(details, "Исходный список list был изменён")
            end
        else
            _G.test5 = "Проверка исходного list | Ошибка: " .. tostring(result)
            table.insert(details, "Ошибка при проверке изменения исходного списка: " .. tostring(result))
        end

        if #details > 0 then
            _G.checkError = "Проверка результата не пройдена"
            return table.concat(details, "\n")
        end

        return true
    end,
}

ns_llua['lua'][52.8] = {
    type = "commenttest",
    title = "Практика: фильтрация списка через таблицу-множество",
    helpModules = {52.2, 52.4, 31, 29.1, 45},
    preloadVars = {
        {var = "FilterAllowed", desc = "FilterAllowed очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
        {var = "test5", desc = "test5 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
        "test5",
    },
    instruction = [=[
<h>Практика: фильтрация списка через таблицу-множество</h>
<t>Создай глобальную функцию <k>FilterAllowed(items, allowedSet)</k>.</t>

<t>Функция получает два аргумента:</t>
<c>items — массив элементов;</c>
<c>allowedSet — таблица-множество, где разрешённые элементы имеют значение true.</c>

<t>Что должна сделать функция:</t>
<c>1. Пройти по всем элементам items.</c>
<c>2. Проверить, разрешён ли каждый элемент в allowedSet.</c>
<c>3. Собрать новый массив только из разрешённых элементов.</c>
<c>4. Вернуть новый массив-результат.</c>

<t>Дополнительные условия:</t>
<c>Если items не является таблицей, верни пустую таблицу.</c>
<c>Если allowedSet не является таблицей, верни пустую таблицу.</c>
<c>Исходный items менять нельзя.</c>
]=],
    initialCode = [=[
function FilterAllowed(items, allowedSet)

end
]=],
    requireKeywords = {
        "FilterAllowed",
        "function",
        "return",
    },
    checkCode = function()
        local details = {}

        _G.checkError = nil

        for i = 1, 5 do
            _G["test" .. i] = nil
        end

        if type(_G.FilterAllowed) ~= "function" then
            _G.checkError = "FilterAllowed должна быть глобальной функцией"
            return _G.checkError
        end

        local function sameArrays(a, b)
            if type(a) ~= "table" or type(b) ~= "table" then
                return false
            end

            if #a ~= #b then
                return false
            end

            for i = 1, #a do
                if a[i] ~= b[i] then
                    return false
                end
            end

            return true
        end

        local function fmtScalar(value)
            if type(value) == "string" then
                return '"' .. value .. '"'
            end

            return tostring(value)
        end

        local function fmtArray(t)
            if type(t) ~= "table" then
                return tostring(t)
            end

            local parts = {}

            for i = 1, #t do
                parts[i] = fmtScalar(t[i])
            end

            return "{" .. table.concat(parts, ", ") .. "}"
        end

        local function fmtMap(t)
            if type(t) ~= "table" then
                return tostring(t)
            end

            local keys = {}

            for k in pairs(t) do
                table.insert(keys, k)
            end

            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b)
            end)

            local parts = {}

            for _, k in ipairs(keys) do
                table.insert(parts, tostring(k) .. "=" .. fmtScalar(t[k]))
            end

            return "{" .. table.concat(parts, ", ") .. "}"
        end

        local tests = {
            {
                name = "обычная фильтрация",
                items = {"яблоко", "банан", "вишня"},
                allowedSet = {["яблоко"] = true, ["вишня"] = true},
                expected = {"яблоко", "вишня"},
            },
            {
                name = "пустой items",
                items = {},
                allowedSet = {["яблоко"] = true},
                expected = {},
            },
            {
                name = "items не таблица",
                items = nil,
                allowedSet = {["яблоко"] = true},
                expected = {},
            },
            {
                name = "allowedSet не таблица",
                items = {"яблоко"},
                allowedSet = nil,
                expected = {},
            },
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(_G.FilterAllowed, test.items, test.allowedSet)

            local resultText
            if ok then
                resultText = fmtArray(result)
            else
                resultText = "ошибка: " .. tostring(result)
            end

            local line = string.format(
                "%s | Вход: items=%s, allowedSet=%s | Получено: %s | Ожидалось: %s",
                test.name,
                fmtArray(test.items),
                fmtMap(test.allowedSet),
                resultText,
                fmtArray(test.expected)
            )

            _G["test" .. i] = line

            if not ok or not sameArrays(result, test.expected) then
                table.insert(details, line)
            end
        end

        local original = {"яблоко"}
        local allowedSet = {["яблоко"] = true}
        local ok, result = pcall(_G.FilterAllowed, original, allowedSet)

        if ok then
            _G.test5 = 'Проверка исходного items | Вход: items={"яблоко"} | Получено: '
                .. fmtArray(original)
                .. ' | Ожидалось: {"яблоко"}'

            if #original ~= 1 or original[1] ~= "яблоко" then
                table.insert(details, "Исходный список items был изменён")
            end
        else
            _G.test5 = "Проверка исходного items | Ошибка: " .. tostring(result)
            table.insert(details, "Ошибка при проверке изменения исходного списка: " .. tostring(result))
        end

        if #details > 0 then
            _G.checkError = "Проверка результата не пройдена"
            return table.concat(details, "\n")
        end

        return true
    end,
}

ns_llua['lua'][52.9] = {
    type = "commenttest",
    title = "Итоговый комбо-тест: lookup-таблицы и отчёт",
    helpModules = {52.2, 31, 31.2, 7, 44, 45},
    preloadVars = {
        {var = "BuildTeamReport", desc = "BuildTeamReport очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
        {var = "test5", desc = "test5 очищается перед проверкой"},
        {var = "test6", desc = "test6 очищается перед проверкой"},
        {var = "test7", desc = "test7 очищается перед проверкой"},
        {var = "test8", desc = "test8 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
        "test5",
        "test6",
        "test7",
        "test8",
    },
    instruction = [=[
<h>Итоговый комбо-тест: lookup-таблицы и отчёт</h>
<t>Создай глобальную функцию <k>BuildTeamReport(players, playerTeams, teamNames, banned)</k>.</t>

<t>Функция получает четыре аргумента:</t>
<c>players — массив имён игроков;</c>
<c>playerTeams — таблица: имя игрока -> код команды;</c>
<c>teamNames — таблица: код команды -> текст команды;</c>
<c>banned — таблица-множество: имя игрока -> true.</c>

<t>Что должна сделать функция:</t>
<c>1. Пройти по всем игрокам из players.</c>
<c>2. Пропустить игроков, которые есть в banned.</c>
<c>3. Для остальных найти код команды в playerTeams.</c>
<c>4. По коду команды найти текст команды в teamNames.</c>
<c>5. Если команду или текст команды найти не удалось, использовать "Неизвестно".</c>
<c>6. Собрать отчёт по разрешённым игрокам.</c>

<t>Формат отчёта:</t>
<c>Для каждого разрешённого игрока: имя: команда.</c>
<c>Части отчёта разделяются "; ".</c>

<t>Функция должна вернуть два значения:</t>
<c>1. количество разрешённых игроков;</c>
<c>2. строку отчёта.</c>

<t>Если разрешённых игроков нет, строка отчёта должна быть пустой.</t>

<t>Дополнительные условия:</t>
<c>Если players не является таблицей, верни 0 и пустую строку.</c>
<c>Если playerTeams, teamNames или banned не являются таблицами, считай их пустыми таблицами.</c>
<c>Входные таблицы менять нельзя.</c>
]=],
    initialCode = [=[
function BuildTeamReport(players, playerTeams, teamNames, banned)
    
end
]=],
    requireKeywords = {
        "BuildTeamReport",
        "function",
        "return",
    },
    checkCode = function()
        local details = {}

        _G.checkError = nil

        for i = 1, 8 do
            _G["test" .. i] = nil
        end

        if type(_G.BuildTeamReport) ~= "function" then
            _G.checkError = "BuildTeamReport должна быть глобальной функцией"
            return _G.checkError
        end

        local function fmtScalar(value)
            if type(value) == "string" then
                return '"' .. value .. '"'
            end

            return tostring(value)
        end

        local function fmtArray(t)
            if type(t) ~= "table" then
                return tostring(t)
            end

            local parts = {}

            for i = 1, #t do
                parts[i] = fmtScalar(t[i])
            end

            return "{" .. table.concat(parts, ", ") .. "}"
        end

        local function fmtMap(t)
            if type(t) ~= "table" then
                return tostring(t)
            end

            local keys = {}

            for k in pairs(t) do
                table.insert(keys, k)
            end

            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b)
            end)

            local parts = {}

            for _, k in ipairs(keys) do
                table.insert(parts, tostring(k) .. "=" .. fmtScalar(t[k]))
            end

            return "{" .. table.concat(parts, ", ") .. "}"
        end

        local testIndex = 0

        local function addTest(name, players, playerTeams, teamNames, banned, expectedCount, expectedReport)
            testIndex = testIndex + 1

            local ok, count, report = pcall(_G.BuildTeamReport, players, playerTeams, teamNames, banned)

            local countText
            local reportText

            if ok then
                countText = fmtScalar(count)
                reportText = fmtScalar(report)
            else
                countText = "ошибка: " .. tostring(count)
                reportText = "nil"
            end

            local line = string.format(
                "%s | Вход: players=%s, playerTeams=%s, teamNames=%s, banned=%s | Получено: count=%s, report=%s | Ожидалось: count=%s, report=%s",
                name,
                fmtArray(players),
                fmtMap(playerTeams),
                fmtMap(teamNames),
                fmtMap(banned),
                countText,
                reportText,
                fmtScalar(expectedCount),
                fmtScalar(expectedReport)
            )

            _G["test" .. testIndex] = line

            if not ok or count ~= expectedCount or report ~= expectedReport then
                table.insert(details, line)
            end
        end

        addTest(
            "обычный отчёт",
            {"Артас", "Джайна", "Гулдан"},
            {["Артас"] = "RED", ["Джайна"] = "BLUE"},
            {RED = "Красные", BLUE = "Синие"},
            {["Гулдан"] = true},
            2,
            "Артас: Красные; Джайна: Синие"
        )

        addTest(
            "команда не найдена",
            {"Тралл"},
            {},
            {},
            {},
            1,
            "Тралл: Неизвестно"
        )

        addTest(
            "все забанены",
            {"Гулдан"},
            {["Гулдан"] = "RED"},
            {RED = "Красные"},
            {["Гулдан"] = true},
            0,
            ""
        )

        addTest(
            "players не таблица",
            nil,
            {},
            {},
            {},
            0,
            ""
        )

        addTest(
            "banned nil",
            {"Артас"},
            {["Артас"] = "RED"},
            {RED = "Красные"},
            nil,
            1,
            "Артас: Красные"
        )

        addTest(
            "playerTeams nil",
            {"Артас"},
            nil,
            {RED = "Красные"},
            nil,
            1,
            "Артас: Неизвестно"
        )

        addTest(
            "teamNames nil",
            {"Артас"},
            {["Артас"] = "RED"},
            nil,
            nil,
            1,
            "Артас: Неизвестно"
        )

        local players = {"Артас"}
        local playerTeams = {["Артас"] = "RED"}
        local teamNames = {RED = "Красные"}
        local expectedPlayersText = '{"Артас"}'

        testIndex = testIndex + 1

        local ok, err = pcall(_G.BuildTeamReport, players, playerTeams, teamNames, nil)

        if ok then
            _G.test8 = "Проверка исходного players | Вход: players="
                .. expectedPlayersText
                .. " | Получено: "
                .. fmtArray(players)
                .. " | Ожидалось: "
                .. expectedPlayersText

            if #players ~= 1 or players[1] ~= "Артас" then
                table.insert(details, "Исходный список players был изменён")
            end
        else
            _G.test8 = "Проверка исходного players | Ошибка: " .. tostring(err)
            table.insert(details, "Ошибка при проверке изменения исходного списка players")
        end

        if #details > 0 then
            _G.checkError = "Проверка результата не пройдена"
            return table.concat(details, "\n")
        end

        return true
    end,
}
















































































































































ns_llua['lua'][53] = {
type = "info",
title = "Мост Lua и WoW API",
content = [=[
<h>Мост Lua и WoW API</h>
<t>Первая часть курса дала базу: переменные, типы, условия, циклы, таблицы и функции. Теперь применяем её к WoW API.</t>
<t>WoW API — это готовые игровые функции. Они возвращают данные об игроке, цели, группе, сумках, заклинаниях и мире.</t>
<h>Простые запросы</h>
<code>
/run print(UnitName("player")) -- вывести имя персонажа
/run print(UnitLevel("player")) -- вывести уровень персонажа
/run print(UnitHealth("player")) -- вывести текущее здоровье персонажа
</code>
<h>Несколько возвращаемых значений</h>
<t>Некоторые API-функции возвращают сразу несколько значений. Для них используем множественное присваивание.</t>
<code>
/run local className, classToken = UnitClass("player"); print(className, classToken) -- получить имя класса и технический токен, затем вывести их
</code>
<t>Например, функция может вернуть название класса и технический токен:</t>
<code>
-- Пример возможного вывода:
-- Воин   WARRIOR
</code>
<h>Таблица с данными API</h>
<code>
/run playerInfo = { name = UnitName("player"), level = UnitLevel("player") }; print(playerInfo.name, playerInfo.level) -- создать глобальную таблицу с полями name и level, затем вывести их
</code>
<w>Важно:</w> если практический модуль проверяет переменную, создавай её глобальной, то есть без <k>local</k>.
<h>Зачем это нужно</h>
<t>Дальше мы будем получать данные о юнитах, считать проценты здоровья, перебирать группы и сумки, а затем создавать простые элементы интерфейса.</t>
]=],
}

ns_llua['lua'][54] = {
type = "vartest",
title = "Практика: имя и уровень игрока",
helpModules = {53},
tasks = {
{
var = "apiPlayerName",
desc = 'Создай глобальную переменную apiPlayerName и помести в неё имя игрока. Значение получи через WoW API, команду /run составь самостоятельно.',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "apiPlayerLevel",
desc = 'Создай глобальную переменную apiPlayerLevel и помести в неё уровень игрока. Значение получи через WoW API, команду /run составь самостоятельно.',
check = function(value)
return type(value) == "number" and value > 0
end,
},
},
}

ns_llua['lua'][55] = {
type = "vartest",
title = "Практика: таблица результатов класса",
helpModules = {53, 45},
tasks = {
{
var = "apiClassTable",
desc = 'Создай глобальную таблицу apiClassTable и помести в неё оба результата API-функции класса игрока: название класса и технический токен. Выполни действие через /run, одним или двумя шагами.',
check = function(value)
return type(value) == "table"
and type(value[1]) == "string"
and value[1] ~= ""
and type(value[2]) == "string"
and value[2] ~= ""
end,
},
},
}

ns_llua['lua'][56] = {
type = "commenttest",
title = "Тест: функция GetPlayerNameAndLevel",
helpModules = {53, 45},
preloadVars = {
{var = "GetPlayerNameAndLevel", desc = "GetPlayerNameAndLevel очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 53-3: функция GetPlayerNameAndLevel</h>
<t>Создай глобальную функцию <k>GetPlayerNameAndLevel()</k>.</t>
<t>Функция должна вернуть два значения:</t>
<c>1</c> — имя игрока через <k>UnitName("player")</k>.
<c>2</c> — уровень игрока через <k>UnitLevel("player")</k>.
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetPlayerNameAndLevel()
]=],
requireKeywords = {
"GetPlayerNameAndLevel",
"function",
"UnitName",
"UnitLevel",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetPlayerNameAndLevel) ~= "function" then
_G.checkError = "GetPlayerNameAndLevel не является глобальной функцией"
return false
end
local ok, name, level = pcall(_G.GetPlayerNameAndLevel)
if not ok then
_G.checkError = "Ошибка вызова GetPlayerNameAndLevel: " .. tostring(name)
return false
end
if type(name) ~= "string" or name == "" then
_G.checkError = "Первым значением функция должна вернуть имя игрока"
return false
end
if type(level) ~= "number" or level <= 0 then
_G.checkError = "Вторым значением функция должна вернуть уровень игрока"
return false
end
return true
end,
}

ns_llua['lua'][57] = {
type = "commenttest",
title = "Тест: строка playerSummary",
helpModules = {53, 7, 14},
preloadVars = {
{var = "playerSummary", desc = "playerSummary очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
"playerSummary",
},
instruction = [=[
<h>Тест: строка playerSummary</h>
<t>Создай глобальную переменную <k>playerSummary</k>.</t>
<t>Используй <k>string.format</k> и шаблон:</t>
<c>"%s/%d"</c>
<t>Первым аргументом подставь имя игрока через <k>UnitName("player")</k>.</t>
<t>Вторым аргументом подставь уровень игрока через <k>UnitLevel("player")</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную переменную playerSummary
]=],
requireKeywords = {
"playerSummary",
"string.format",
"UnitName",
"UnitLevel",
},
checkCode = function()
_G.checkError = nil

local name = UnitName("player") or ""
local level = UnitLevel("player") or 0

if type(_G.playerSummary) ~= "string" or _G.playerSummary == "" then
_G.checkError = "playerSummary должна быть непустой строкой"
return false
end

local expected = string.format("%s/%d", name, level)

if _G.playerSummary ~= expected then
_G.checkError = "playerSummary должна быть строкой вида имя/уровень, например Игрок/10"
return false
end

return true
end,
}

ns_llua['lua'][58] = {
type = "commenttest",
title = "Тест: таблица playerInfo",
helpModules = {53, 44, 45},
preloadVars = {
{var = "playerInfo", desc = "playerInfo очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
"playerInfo",
},
instruction = [=[
<h>Тест 53-5: таблица playerInfo</h>
<t>Создай глобальную таблицу <k>playerInfo</k> с полями:</t>
<c>name</c> — имя игрока через <k>UnitName("player")</k>.
<c>level</c> — уровень игрока через <k>UnitLevel("player")</k>.
<c>class</c> — название класса через первый результат <k>UnitClass("player")</k>.
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную таблицу playerInfo
]=],
requireKeywords = {
"playerInfo",
"UnitName",
"UnitLevel",
"UnitClass",
},
checkCode = function()
_G.checkError = nil
local info = _G.playerInfo
if type(info) ~= "table" then
_G.checkError = "playerInfo должна быть таблицей"
return false
end
if type(info.name) ~= "string" or info.name == "" then
_G.checkError = "Поле name должно быть строкой с именем игрока"
return false
end
if type(info.level) ~= "number" or info.level <= 0 then
_G.checkError = "Поле level должно быть числом больше нуля"
return false
end
if type(info.class) ~= "string" or info.class == "" then
_G.checkError = "Поле class должно быть строкой с названием класса"
return false
end
return true
end,
}

ns_llua['lua'][59] = {
type = "info",
title = "Особенности WoW API 3.3.5",
content = [=[
<h>Особенности WoW API 3.3.5</h>
<t>У WoW API есть несколько важных особенностей, которые нужно понимать с самого начала.</t>
<h>1. Многие функции возвращают 1 или nil</h>
<t>В старых версиях WoW многие проверки возвращают не классический <k>true</k> или <k>false</k>, а <k>1</k> или <k>nil</k>.</t>
<code>
/run print(UnitExists("player"), type(UnitExists("player"))) -- результат: 1 number. То есть вернулась 1, и её тип — number, а не boolean
</code>
<t>Поэтому лучше писать так:</t>
<code>
/run if UnitExists("target") then print("Цель есть") end -- если цель есть, выведет: Цель есть
</code>
<t>И не стоит писать так:</t>
<code>
/run if UnitExists("target") == true then print("Цель есть") end -- выведет ничего: UnitExists вернул 1, а 1 == true даёт false
</code>
<w>Причина:</w> если функция вернула <k>1</k>, то <k>1 == true</k> даст <k>false</k>.
<h>2. nil означает отсутствие данных</h>
<t>Если юнита нет, API часто возвращает <k>nil</k>.</t>
<code>
/run print(UnitName("target")) -- с целью: Шеф nil (имя + сервер, на своём сервере — nil). Без цели: nil nil
</code>
<t>Если цели нет, оба значения будут <k>nil</k>. Обрати внимание: <k>UnitName</k> возвращает два значения, второе — сервер.</t>
<h>3. Локализованные имена и технические токены</h>
<t>Некоторые функции возвращают два значения: понятное имя и технический код.</t>
<code>
/run local name, token = UnitClass("player"); print(name, token) -- пример: Рыцарь смерти DEATHKNIGHT
</code>
<t>Для вывода игроку лучше использовать <k>name</k>.</t>
<t>Для логики лучше использовать <k>token</k>, потому что он одинаковый у всех клиентов.</t>
<code>
/run local _, token = UnitClass("player"); if token == "WARRIOR" then print("Это воин") end -- у рыцаря смерти выведет ничего: токен DEATHKNIGHT, а не WARRIOR
</code>
<h>4. Отладка через /dump</h>
<t>Если не знаешь, что возвращает функция, используй <k>/dump</k>.</t>
<code>
/dump UnitClass("player")
-- результат: [1]="Рыцарь смерти", [2]="DEATHKNIGHT"
/dump UnitHealth("player")
-- результат: [1]=49045 — текущее здоровье
/dump GetMoney()
-- результат: [1]=205606460 — деньги в меди (примерно 20560 золота)
</code>
<h>5. Не все данные доступны мгновенно</h>
<t>Некоторые функции могут вернуть <k>nil</k>, если данные ещё не загрузились или кэш ещё не готов. Позже мы встретим это у предметов и гильдии.</t>
]=],
}

ns_llua['lua'][60] = {
type = "commenttest",
title = "Практика: имя цели, если цель есть",
helpModules = {59, 77},
preloadVars = {
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Практика: имя цели, если цель есть</h>
<t>Напиши код, который проверяет, существует ли текущая цель.</t>
<t>Если цель существует — выведи её имя через <k>print</k>.</t>
<t>Если цели нет — ничего выводить не нужно.</t>
<t>Перед запуском выбери кого-нибудь в таргет, например себя.</t>
]=],
initialCode = [=[
-- Если цель есть, выведи её имя
]=],
requireKeywords = {
"if",
"then",
"end",
"UnitExists",
"UnitName",
"print",
"\"target\"",
},
checkCode = function()
_G.checkError = nil

if not UnitExists("target") then
_G.checkError = "Сейчас нет цели: выбери цель (например, себя) и запусти код ещё раз"
return false
end

local name = UnitName("target")

if type(name) ~= "string" or name == "" then
_G.checkError = "Имя цели не читается: проверь, что цель выбрана, и запусти код ещё раз"
return false
end

return true
end,
}

ns_llua['lua'][61] = {
type = "commenttest",
title = "Практика: IsSameClass и таргет своего класса",
helpModules = {59, 45, 77},
preloadVars = {
{var = "IsSameClass", desc = "IsSameClass очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Практика: функция IsSameClass</h>
<t>Найди другого игрока своего класса (например, в городе или в группе) и возьми его в таргет.</t>
<t>Создай глобальную функцию <k>IsSameClass()</k>.</t>
<t>Функция должна вернуть <k>true</k>, если технический токен класса текущей цели совпадает с твоим токеном, и <k>false</k> иначе.</t>
<t>Сравнивай именно технические токены — вторые значения <k>UnitClass</k>, а не локализованные названия классов.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию IsSameClass()
]=],
requireKeywords = {
"IsSameClass",
"function",
"UnitClass",
"return",
},
checkCode = function()
_G.checkError = nil

if type(_G.IsSameClass) ~= "function" then
_G.checkError = "IsSameClass не является глобальной функцией"
return false
end

-- Хитрая проверка на тестовых данных: временно подменяем UnitClass.
local realUnitClass = UnitClass

local function RunWithFakeTokens(playerToken, targetToken)
_G.UnitClass = function(unit)
if unit == "player" then
return "Фейк", playerToken
end
if unit == "target" then
return "Фейк", targetToken
end
return realUnitClass(unit)
end
local ok, result = pcall(_G.IsSameClass)
_G.UnitClass = realUnitClass
if not ok then
return nil, result
end
return result, nil
end

local sameResult, sameErr = RunWithFakeTokens("WARRIOR", "WARRIOR")
if sameResult == nil then
_G.checkError = "Ошибка вызова IsSameClass на тестовых данных: " .. tostring(sameErr)
return false
end
if sameResult ~= true then
_G.checkError = "При совпадающих токенах классов функция должна вернуть true"
return false
end

local diffResult, diffErr = RunWithFakeTokens("WARRIOR", "MAGE")
if diffResult == nil then
_G.checkError = "Ошибка вызова IsSameClass на тестовых данных: " .. tostring(diffErr)
return false
end
if diffResult ~= false then
_G.checkError = "При разных токенах функция должна вернуть false: проверь, что сравниваешь токены через UnitClass, а не захардкодил значение"
return false
end

-- Теперь реальный мир: целью должен быть ДРУГОЙ игрок того же класса.
if not UnitExists("target") then
_G.checkError = "Нет цели: найди игрока своего класса и возьми его в таргет"
return false
end

if not UnitIsPlayer("target") then
_G.checkError = "Цель не является игроком: нужен другой игрок твоего класса"
return false
end

if UnitIsUnit("player", "target") then
_G.checkError = "Ты выбрал в таргет себя. Нужен другой игрок"
return false
end

local playerToken = select(2, UnitClass("player"))
local targetToken = select(2, UnitClass("target"))

if playerToken ~= targetToken then
_G.checkError = "Класс цели (" .. tostring(targetToken) .. ") не совпадает с твоим (" .. tostring(playerToken) .. "). Найди игрока своего класса"
return false
end

local ok, result = pcall(_G.IsSameClass)
if not ok then
_G.checkError = "Ошибка вызова IsSameClass: " .. tostring(result)
return false
end

if result ~= true then
_G.checkError = "При цели своего класса функция должна вернуть true, получено: " .. tostring(result)
return false
end

return true
end,
}

ns_llua['lua'][62] = {
type = "commenttest",
title = "Практика: HasTarget и чистый boolean",
helpModules = {59, 15},
preloadVars = {
{var = "HasTarget", desc = "HasTarget очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Практика: функция HasTarget</h>
<t>Создай глобальную функцию <k>HasTarget()</k>.</t>
<t>Функция должна вернуть <k>true</k>, если текущая цель существует, и <k>false</k>, если цели нет.</t>
<t>Помни: <k>UnitExists</k> возвращает <k>1</k> или <k>nil</k>, а не boolean. Значит, тебе нужно преобразовать значение в чистый boolean.</t>
<h>Двойное отрицание</h>
<t>Первый <k>not</k> превращает любое значение в boolean и переворачивает его: всё истинное становится <k>false</k>, а <k>nil</k> — <k>true</k>. Второй <k>not</k> переворачивает обратно. Смысл значения сохраняется, но тип становится строго boolean.</t>
<code>
/run print(not 1, not nil) -- false true
/run print(not not 1, not not nil) -- true false
</code>
<t>Примени двойное отрицание к результату проверки существования цели, чтобы функция вернула именно <k>true</k> или <k>false</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию HasTarget()
]=],
requireKeywords = {
"HasTarget",
"function",
"UnitExists",
"return",
},
checkCode = function()
_G.checkError = nil

if type(_G.HasTarget) ~= "function" then
_G.checkError = "HasTarget не является глобальной функцией"
return false
end

-- Проверяем логику на тестовых данных: временно подменяем UnitExists.
local realUnitExists = UnitExists

local function RunWithFakeExists(fakeValue)
_G.UnitExists = function(unit)
if unit == "target" then
return fakeValue
end
return realUnitExists(unit)
end
local ok, result = pcall(_G.HasTarget)
_G.UnitExists = realUnitExists
return ok, result
end

local okYes, yesResult = RunWithFakeExists(1)
if not okYes then
_G.checkError = "Ошибка вызова HasTarget на тестовых данных: " .. tostring(yesResult)
return false
end
if yesResult ~= true then
_G.checkError = "При существующей цели функция должна вернуть true, получено: " .. tostring(yesResult) .. ". UnitExists вернул 1 — преобразуй его в boolean"
return false
end

local okNo, noResult = RunWithFakeExists(nil)
if not okNo then
_G.checkError = "Ошибка вызова HasTarget на тестовых данных: " .. tostring(noResult)
return false
end
if noResult ~= false then
_G.checkError = "При отсутствии цели функция должна вернуть false, получено: " .. tostring(noResult) .. ". nil нужно преобразовать в false"
return false
end

-- Контрольный вызов в реальном состоянии.
local expected = UnitExists("target") and true or false
local okReal, realResult = pcall(_G.HasTarget)
if not okReal then
_G.checkError = "Ошибка вызова HasTarget: " .. tostring(realResult)
return false
end
if realResult ~= expected then
_G.checkError = "Функция вернула неверное значение для текущего состояния цели"
return false
end

return true
end,
}

ns_llua['lua'][63] = {
type = "commenttest",
title = "Тест: функция GetPlayerClassToken",
helpModules = {59, 45},
preloadVars = {
{var = "GetPlayerClassToken", desc = "GetPlayerClassToken очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест: функция GetPlayerClassToken</h>
<t>Создай глобальную функцию <k>GetPlayerClassToken()</k>.</t>
<t>Функция должна вернуть только токен класса игрока.</t>
<t>Используй <k>select</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetPlayerClassToken()
]=],
requireKeywords = {
"GetPlayerClassToken",
"function",
"select",
"UnitClass",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetPlayerClassToken) ~= "function" then
_G.checkError = "GetPlayerClassToken не является глобальной функцией"
return false
end
local ok, token = pcall(_G.GetPlayerClassToken)
if not ok then
_G.checkError = "Ошибка вызова GetPlayerClassToken: " .. tostring(token)
return false
end
if type(token) ~= "string" or token == "" then
_G.checkError = "Функция должна вернуть строку с токеном класса"
return false
end
if token ~= token:upper() then
_G.checkError = "Токен класса должен быть в верхнем регистре"
return false
end
return true
end,
}

ns_llua['lua'][64] = {
type = "commenttest",
title = ": функция SafeUnitName",
helpModules = {59},
preloadVars = {
{var = "SafeUnitName", desc = "SafeUnitName очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест: функция SafeUnitName</h>
<t>Создай глобальную функцию <k>SafeUnitName(unit)</k>.</t>
<t>Функция должна вернуть имя юнита через <k>UnitName(unit)</k>.</t>
<t>Если имени нет, функция должна вернуть строку:</t>
<s>"Нет юнита"</s>
<t>Используй <k>or</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию SafeUnitName(unit)
]=],
requireKeywords = {
"SafeUnitName",
"function",
"UnitName",
"or",
"return",
},
checkCode = function()
_G.checkError = nil

if type(_G.SafeUnitName) ~= "function" then
_G.checkError = "SafeUnitName не является глобальной функцией"
return false
end

-- Ловим хардкод: функция должна использовать аргумент, а не фиксированный юнит.
local realUnitName = UnitName

local function RunWithFakeNames(unit)
_G.UnitName = function(u)
if u == "player" then
return "МаркерИгрока", nil
end
if u == "target" then
return "МаркерЦели", nil
end
return nil, nil
end
local ok, result = pcall(_G.SafeUnitName, unit)
_G.UnitName = realUnitName
return ok, result
end

local okFake1, fake1 = RunWithFakeNames("player")
if not okFake1 then
_G.checkError = "Ошибка вызова SafeUnitName на тестовых данных: " .. tostring(fake1)
return false
end
if fake1 ~= "МаркерИгрока" then
_G.checkError = "Функция должна запрашивать имя того юнита, что передан аргументом. Не подставляй \"target\" внутрь функции — используй unit"
return false
end

local okFake2, fake2 = RunWithFakeNames("ns_invalid_unit")
if not okFake2 then
_G.checkError = "Ошибка вызова SafeUnitName на тестовых данных: " .. tostring(fake2)
return false
end
if fake2 ~= "Нет юнита" then
_G.checkError = "Для юнита без имени функция должна вернуть \"Нет юнита\", даже в тестовых данных"
return false
end

local ok1, result1 = pcall(_G.SafeUnitName, "player")
if not ok1 then
_G.checkError = "Ошибка вызова SafeUnitName('player'): " .. tostring(result1)
return false
end
if result1 ~= UnitName("player") then
_G.checkError = "Для player функция должна вернуть имя игрока"
return false
end

local ok2, result2 = pcall(_G.SafeUnitName, "ns_invalid_unit")
if not ok2 then
_G.checkError = "Ошибка вызова SafeUnitName('ns_invalid_unit'): " .. tostring(result2)
return false
end
if result2 ~= "Нет юнита" then
_G.checkError = "Для несуществующего юнита функция должна вернуть 'Нет юнита'"
return false
end

return true
end,
}

ns_llua['lua'][65] = {
type = "info",
title = "Безопасные шаблоны API",
helpModules = {53, 59},
content = [=[
<h>Безопасные шаблоны API</h>
<t>API часто может вернуть <k>nil</k>. Поэтому сразу учимся писать безопасный код.</t>
<h>Проверка юнита</h>
<code>
/run if UnitExists("target") then print("Цель существует") else print("Цели нет") end
</code>
<h>Значение по умолчанию через or</h>
<code>
/run local name = UnitName("target") or "Нет цели"; print(name)
</code>
<t>Если <k>UnitName</k> вернул <k>nil</k>, переменная получит строку <s>"Нет цели"</s>.</t>
<h>Число по умолчанию через or 0</h>
<code>
/run local hp = UnitHealth("player") or 0; print(hp)
</code>
<h>Защита от деления на ноль</h>
<code>
/run local hp = UnitHealth("player") or 0; local hpMax = UnitHealthMax("player") or 0; if hpMax > 0 then print(math.floor(hp / hpMax * 100)) else print(0) end
</code>
<w>Важно:</w> нельзя делить на <k>0</k> и ожидать нормальный результат. Всегда проверяй знаменатель.
<h>tonumber для странных значений</h>
<t>Если значение может быть строкой, преобразуй его в число.</t>
<code>
/run local value = tonumber("1500") or 0; print(value + 1)
</code>
<h>Шаблон безопасной функции</h>
<code>
function GetSafeHealthPercent(unit)
    local hp = UnitHealth(unit) or 0
    local hpMax = UnitHealthMax(unit) or 0
    if hpMax <= 0 then
        return 0
    end
    return math.floor(hp / hpMax * 100)
end
</code>
<t>Такой подход будет использоваться почти во всех модулях второй части.</t>
]=],
}

ns_llua['lua'][66] = {
    type = "commenttest",
    title = "Тест 65-1: безопасный снимок юнита",
    helpModules = {65, 53, 59, 45},
    preloadVars = {
        {var = "GetSafeUnitSnapshot", desc = "GetSafeUnitSnapshot очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "targetSnapshot", desc = "targetSnapshot очищается перед проверкой"},
    },
    reportVars = {"checkError", "targetSnapshot"},
    instruction = [=[
<h>Тест 65-1: безопасный снимок юнита</h>
<t>Создай глобальную функцию <k>GetSafeUnitSnapshot(unit)</k>.</t>
<t>Функция должна вернуть новую таблицу с полями:</t>
<c>exists</c> — <k>true</k>, если юнит существует, иначе <k>false</k>.
<c>name</c> — имя юнита или <s>"Нет юнита"</s>.
<c>level</c> — уровень юнита. Если уровня нет или он меньше нуля, верни <n>0</n>.
<t>Используй:</t>
<c>UnitExists(unit)</c>
<c>UnitName(unit)</c>
<c>UnitLevel(unit)</c>
<t>Для boolean приведи результат <k>UnitExists</k> к чистому <k>true</k>/<k>false</k>.</t>
<t>Для имени используй запасное значение через <k>or</k>.</t>
<t>Для уровня сделай защиту от <k>nil</k> и отрицательного значения.</t>
<w>Не создавай глобальные переменные внутри функции. Используй <k>local</k> или сразу возвращай таблицу через <k>return</k>.</w>
<t>Ничего выводить не нужно.</t>
]=],
    initialCode = [=[
-- Создай глобальную функцию GetSafeUnitSnapshot(unit)
]=],
    requireKeywords = {
        "GetSafeUnitSnapshot",
        "function",
        "UnitExists",
        "UnitName",
        "UnitLevel",
        "or",
        "return",
        "Нет юнита",
        "0",
    },
    checkCode = function()
        _G.checkError = nil
        _G.targetSnapshot = nil

        if type(_G.GetSafeUnitSnapshot) ~= "function" then
            _G.checkError = "GetSafeUnitSnapshot не является глобальной функцией"
            return false
        end

        local function getExpectedExists(unit)
            return UnitExists(unit) and true or false
        end

        local function getExpectedName(unit)
            local name = UnitName(unit)

            if name == nil then
                return "Нет юнита"
            end

            return name
        end

        local function getExpectedLevel(unit)
            local level = tonumber(UnitLevel(unit))

            if level == nil or level < 0 then
                return 0
            end

            return math.floor(level)
        end

        local function checkSnapshot(unit, caseName)
            local ok, snapshot = pcall(_G.GetSafeUnitSnapshot, unit)

            if not ok then
                _G.checkError = caseName .. ": ошибка вызова GetSafeUnitSnapshot: " .. tostring(snapshot)
                return nil
            end

            if type(snapshot) ~= "table" then
                _G.checkError = caseName .. ": функция должна вернуть таблицу"
                return nil
            end

            local expectedExists = getExpectedExists(unit)
            local expectedName = getExpectedName(unit)
            local expectedLevel = getExpectedLevel(unit)

            if type(snapshot.exists) ~= "boolean" then
                _G.checkError = caseName .. ": поле exists должно быть boolean"
                return nil
            end

            if snapshot.exists ~= expectedExists then
                _G.checkError = caseName .. ": поле exists должно быть " .. tostring(expectedExists)
                return nil
            end

            if type(snapshot.name) ~= "string" or snapshot.name ~= expectedName then
                _G.checkError = caseName .. ": поле name должно быть \"" .. expectedName .. "\""
                return nil
            end

            if type(snapshot.level) ~= "number" or snapshot.level ~= expectedLevel then
                _G.checkError = caseName .. ": поле level должно быть " .. tostring(expectedLevel)
                return nil
            end

            return snapshot
        end

        local playerSnapshot = checkSnapshot("player", "Тест с player")
        if not playerSnapshot then
            return false
        end

        local invalidSnapshot = checkSnapshot("ns_invalid_unit", "Тест с несуществующим юнитом")
        if not invalidSnapshot then
            return false
        end

        local currentTargetSnapshot = checkSnapshot("target", "Тест с target")
        if not currentTargetSnapshot then
            return false
        end

        if playerSnapshot == invalidSnapshot
            or playerSnapshot == currentTargetSnapshot
            or invalidSnapshot == currentTargetSnapshot then
            _G.checkError = "Функция должна возвращать новую таблицу при каждом вызове"
            return false
        end

        if _G.targetSnapshot ~= nil then
            _G.checkError = "Функция не должна создавать глобальную переменную targetSnapshot"
            return false
        end

        return true
    end,
}

ns_llua['lua'][67] = {
    type = "commenttest",
    title = "Тест 67: версия клиента через GetBuildInfo",
    helpModules = {53, 7, 10, 45},
    preloadVars = {
        {var = "GetClientVersionSafe", desc = "GetClientVersionSafe очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "testVersion", desc = "testVersion очищается перед проверкой"},
        {var = "testToc", desc = "testToc очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "testVersion",
        "testToc",
    },
    instruction = [=[
<h>Тест 67: версия клиента через GetBuildInfo</h>
<t>Создай глобальную функцию <k>GetClientVersionSafe()</k>.</t>

<t>Функция должна использовать WoW API:</t>
<c>GetBuildInfo()</c>

<t>Эта функция возвращает несколько значений:</t>
<c>version, build, date, toc</c>

<t>Твоя функция должна вернуть два значения:</t>
<c>version, toc</c>

<t>Если <k>version</k> равно <k>nil</k>, верни строку:</t>
<s>"неизвестно"</s>

<t>Если <k>toc</k> не является числом, верни:</t>
<n>0</n>

<t>Для преобразования <k>toc</k> в число используй:</t>
<c>tonumber</c>

<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function GetClientVersionSafe()

end
]=],
    requireKeywords = {
        "GetClientVersionSafe",
        "function",
        "GetBuildInfo",
        "tonumber",
        "return",
    },
    forbidKeywords = {
        "print",
    },
    checkCode = function()
        _G.checkError = nil
        _G.testVersion = nil
        _G.testToc = nil

        if type(_G.GetClientVersionSafe) ~= "function" then
            _G.checkError = "GetClientVersionSafe не является глобальной функцией"
            return false
        end

        local expectedVersion = "неизвестно"
        local expectedToc = 0

        local okApi, apiVersion, apiBuild, apiDate, apiToc = pcall(GetBuildInfo)

        if okApi then
            if type(apiVersion) == "string" and apiVersion ~= "" then
                expectedVersion = apiVersion
            else
                expectedVersion = "неизвестно"
            end

            expectedToc = tonumber(apiToc) or 0
        end

        local ok, version, toc = pcall(_G.GetClientVersionSafe)

        _G.testVersion = "Получено: "
            .. tostring(version)
            .. " | Ожидалось: "
            .. tostring(expectedVersion)

        _G.testToc = "Получено: "
            .. tostring(toc)
            .. " | Ожидалось: "
            .. tostring(expectedToc)

        if not ok then
            _G.checkError = "Ошибка вызова GetClientVersionSafe: " .. tostring(version)
            return false
        end

        if type(version) ~= "string" then
            _G.checkError = "Первое возвращаемое значение должно быть строкой"
            return false
        end

        if version ~= expectedVersion then
            _G.checkError = "Неверное значение version"
            return false
        end

        if type(toc) ~= "number" then
            _G.checkError = "Второе возвращаемое значение должно быть числом"
            return false
        end

        if toc ~= expectedToc then
            _G.checkError = "Неверное значение toc"
            return false
        end

        return true
    end,
}

ns_llua['lua'][68] = {
    type = "commenttest",
    title = "Тест 65-3: функция SafePercent",
    helpModules = {65, 10, 17},
    preloadVars = {
        {var = "SafePercent", desc = "SafePercent очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
    },
    instruction = [=[
<h>Тест 65-3: функция SafePercent</h>
<t>Создай глобальную функцию <k>SafePercent(hp, hpMax)</k>.</t>
<t>Функция должна вернуть процент здоровья.</t>
<t>Если <k>hpMax</k> меньше или равно нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть:</t>
<code>
-- Делим текущее здоровье на максимальное, умножаем на 100
-- и округляем вниз, чтобы получить целые проценты.
math.floor(hp / hpMax * 100)
</code>

<t>Например, если hp = 50, а hpMax = 100, функция вернёт 50.</t>
<w>Проверка hpMax нужна, чтобы не делить на ноль.</w>
<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function SafePercent(hp, hpMax)

end
]=],
    requireKeywords = {
        "SafePercent",
        "function",
        "if",
        "then",
        "return",
        "math.floor",
    },
    checkCode = function()
        _G.checkError = nil

        if type(_G.SafePercent) ~= "function" then
            _G.checkError = "SafePercent не является глобальной функцией"
            return false
        end

        local tests = {
            {50, 100, 50},
            {10, 0, 0},
            {0, 100, 0},
            {100, 100, 100},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(_G.SafePercent, test[1], test[2])

            if not ok or result ~= test[3] then
                _G.checkError = "Тест " .. i .. " функции SafePercent не пройден"
                return false
            end
        end

        return true
    end,
}

ns_llua['lua'][69] = {
    type = "commenttest",
    title = "Тест 65-4: функция SafeNumber",
    helpModules = {65, 10},
    preloadVars = {
        {var = "SafeNumber", desc = "SafeNumber очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
    },
    instruction = [=[
<h>Тест 65-4: функция SafeNumber</h>
<t>Создай глобальную функцию <k>SafeNumber(value)</k>.</t>

<t>Функция должна вернуть числовое представление переданного значения.</t>

<t>Если значение нельзя превратить в число, функция должна вернуть <n>0</n>.</t>

<t>Во всех остальных случаях функция должна вернуть полученное число.</t>

<w>Бонус: если решение займёт 70 символов или меньше, ты получишь дополнительную награду.</w>

<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function SafeNumber(value)

end
]=],
    requireKeywords = {
        "SafeNumber",
        "function",
        "tonumber",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.test1 = nil
        _G.test2 = nil
        _G.test3 = nil
        _G.test4 = nil

        if type(_G.SafeNumber) ~= "function" then
            _G.checkError = "SafeNumber не является глобальной функцией"
            return false
        end

        local function fmt(v)
            if type(v) == "string" then
                return '"' .. v .. '"'
            elseif type(v) == "nil" then
                return "nil"
            else
                return tostring(v)
            end
        end

        local tests = {
            {"5", 5},
            {"bad", 0},
            {7, 7},
            {"3.5", 3.5},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(_G.SafeNumber, test[1])

            _G["test" .. i] = "Вход: "
                .. fmt(test[1])
                .. " | Получено: "
                .. fmt(result)
                .. " | Ожидалось: "
                .. fmt(test[2])

            if not ok or result ~= test[2] then
                _G.checkError = "Тест " .. i .. " функции SafeNumber не пройден"
                return false
            end
        end

        return true
    end,
}

ns_llua['lua'][70] = {
    type = "commenttest",
    title = "Тест 70: функция HasEnoughMana",
    helpModules = {65, 10, 17},
    preloadVars = {
        {var = "HasEnoughMana", desc = "HasEnoughMana очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
        {var = "test5", desc = "test5 очищается перед проверкой"},
        {var = "test6", desc = "test6 очищается перед проверкой"},
        {var = "test7", desc = "test7 очищается перед проверкой"},
        {var = "test8", desc = "test8 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
        "test5",
        "test6",
        "test7",
        "test8",
    },
    instruction = [=[
<h>Тест 70: функция HasEnoughMana</h>
<t>Создай глобальную функцию <k>HasEnoughMana(currentMana, requiredPercent, maxMana)</k>.</t>

<t>Аргументы:</t>
<c>currentMana</c> — текущее количество маны. Может быть числом, строкой с числом, мусором или nil.
<c>requiredPercent</c> — необходимый процент маны для каста заклинания. Может быть числом, строкой с числом, мусором или nil.
<c>maxMana</c> — максимальное количество маны. Может быть числом, строкой с числом, мусором или nil.

<t>Функция должна:</t>
<t>1. Безопасно преобразовать все три аргумента в числа.</t>
<t>2. Вычислить текущий процент маны от максимума.</t>
<t>3. Вернуть <k>true</k>, если текущего процента хватает для каста, и <k>false</k>, если не хватает.</t>

<t>Если значение нельзя превратить в число, считай его равным <n>0</n>.</t>
<t>Если максимальное количество маны равно нулю или меньше, функция должна вернуть <k>false</k>.</t>

<w>Бонусная награда за компактное решение:</w>
<t>Меньше <n>210</n> символов — <n>2</n> опыта и <n>300</n> репутации.</t>
<t>Меньше <n>140</n> символов — <n>3</n> опыта и <n>500</n> репутации.</t>

<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function HasEnoughMana(currentMana, requiredPercent, maxMana)

end
]=],
    requireKeywords = {
        "HasEnoughMana",
        "function",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.test1 = nil
        _G.test2 = nil
        _G.test3 = nil
        _G.test4 = nil
        _G.test5 = nil
        _G.test6 = nil
        _G.test7 = nil
        _G.test8 = nil

        if type(_G.HasEnoughMana) ~= "function" then
            _G.checkError = "HasEnoughMana не является глобальной функцией"
            return false
        end

        local function fmt(v)
            if type(v) == "string" then
                return '"' .. v .. '"'
            elseif type(v) == "nil" then
                return "nil"
            elseif type(v) == "boolean" then
                return v and "true" or "false"
            else
                return tostring(v)
            end
        end

        local tests = {
            {750, 30, 1000, true},
            {200, 50, 1000, false},
            {"800", "60", "1000", true},
            {"bad", 30, 1000, false},
            {nil, 10, 1000, false},
            {500, 100, 500, true},
            {300, 50, 500, true},
            {100, 50, 0, false},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(_G.HasEnoughMana, test[1], test[2], test[3])

            local rawMana = tonumber(test[1]) or 0
            local rawMax = tonumber(test[3]) or 0
            local currentPercent = 0

            if rawMax > 0 then
                currentPercent = rawMana / rawMax * 100
            end

            _G["test" .. i] = "Вход: "
                .. fmt(test[1]) .. ", " .. fmt(test[2]) .. ", " .. fmt(test[3])
                .. " | Мана: " .. fmt(rawMana) .. "/" .. fmt(rawMax)
                .. " (" .. fmt(currentPercent) .. "%)"
                .. " | Получено: "
                .. fmt(result)
                .. " | Ожидалось: "
                .. fmt(test[4])

            if not ok or result ~= test[4] then
                _G.checkError = "Тест " .. i .. " функции HasEnoughMana не пройден"
                return false
            end
        end

        return true
    end,
}

ns_llua['lua'][71] = {
type = "info",
title = "UnitID: player, target, party, raid",
helpModules = {53, 59, 65},
content = [=[
<h>UnitID: player, target, party, raid</h>
<t>Большинство функций WoW API принимают аргумент <k>unit</k>. Это строка-идентификатор юнита.</t>
<w>Важно:</w> UnitID пишется в кавычках, потому что это строка.
<h>Основные UnitID</h>
<c>"player"</c> — твой персонаж.
<c>"target"</c> — текущая цель.
<c>"mouseover"</c> — юнит под курсором мыши.
<c>"focus"</c> — фокус.
<c>"targettarget"</c> — цель твоей цели.
<c>"playerpet"</c> — твой питомец.
<c>"party1"</c> — первый участник группы.
<c>"party2"</c> — второй участник группы.
<c>"party3"</c> — третий участник группы.
<c>"party4"</c> — четвёртый участник группы.
<c>"raid1"</c> — первый участник рейда.
<c>"raid40"</c> — сороковой участник рейда.
<h>Примеры</h>
<code>
/run print(UnitName("player")) -- имя твоего персонажа
/run print(UnitName("target")) -- имя текущей цели
/run print(UnitName("mouseover")) -- имя юнита под курсором мыши
</code>
<h>Таблица юнитов</h>
<code>
/run units = {"player", "target", "mouseover"} -- создаём список юнитов для проверки
/run for _, unit in ipairs(units) do print(unit, UnitExists(unit)) end -- перебираем список и выводим, существует ли каждый юнит
</code>
<t>Так можно быстро проверить, какие юниты сейчас существуют.</t>
<w>Важно:</w> эти две строки нужно выполнять друг за другом, потому что <k>units</k> создаётся как глобальная переменная.
<h>Частая ошибка</h>
<t>Неправильно:</t>
<code>
/run print(UnitName(player)) -- ОШИБКА: player без кавычек — это переменная, она обычно равна nil
</code>
<t>Правильно:</t>
<code>
/run print(UnitName("player")) -- ПРАВИЛЬНО: "player" — строка-идентификатор юнита
</code>
<t>Без кавычек Lua будет искать переменную <k>player</k>, а она обычно равна <k>nil</k>.</t>
]=],
}

ns_llua['lua'][72] = {
    type = "commenttest",
    title = "Практика: Информация о цели",
    helpModules = {71, 55, 57},
    preloadVars = {
        {var = "GetTargetInfo", desc = "GetTargetInfo очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "testResult", desc = "testResult очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "testResult",
    },
    instruction = [=[
<h>Практика: Информация о цели</h>
<t>Создай глобальную функцию <k>GetTargetInfo()</k>.</t>

<t>Перед проверкой выбери цель в игре.</t>

<t>Функция должна вернуть строку с именем, уровнем и классом текущей цели.</t>

<t>Формат строки:</t>
<c>Имя (уровень) - класс</c>

<t>Пример результата:</t>
<c>Высшая (80) - Паладин</c>

<w>Класс должен быть читаемым, а не токеном.</w>

<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function GetTargetInfo()

end
]=],
    requireKeywords = {
        "GetTargetInfo",
        "function",
        "target",
        "UnitName",
        "UnitLevel",
        "UnitClass",
        "return",
    },
    forbidKeywords = {
        "print",
    },
    checkCode = function()
        _G.checkError = nil
        _G.testResult = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetTargetInfo) ~= "function" then
            return fail("GetTargetInfo не является глобальной функцией")
        end

        local okExists, exists = pcall(UnitExists, "target")

        if not okExists or not exists then
            return fail("Нет цели. Выбери цель и нажми проверку снова.")
        end

        local function fmt(v)
            if type(v) == "string" then
                return '"' .. v .. '"'
            elseif type(v) == "nil" then
                return "nil"
            elseif type(v) == "boolean" then
                return v and "true" or "false"
            else
                return tostring(v)
            end
        end

        local function normalize(s)
            s = tostring(s)
            s = s:gsub("%s+", " ")
            return s:match("^%s*(.-)%s*$")
        end

        local okName, name = pcall(UnitName, "target")

        if not okName or type(name) ~= "string" or name == "" then
            return fail("Не удалось получить имя цели. Выбери цель-игрока и нажми проверку снова.")
        end

        local okLevel, level = pcall(UnitLevel, "target")

        if not okLevel or type(level) ~= "number" then
            return fail("Не удалось получить уровень цели. Выбери цель-игрока и нажми проверку снова.")
        end

        local okClass, class = pcall(UnitClass, "target")

        if not okClass or type(class) ~= "string" or class == "" then
            return fail("Не удалось получить класс цели. Выбери цель-игрока и нажми проверку снова.")
        end

        local expected = name .. " (" .. level .. ") - " .. class

        local ok, result = pcall(_G.GetTargetInfo)

        _G.testResult = "Цель: "
            .. name
            .. " | Получено: "
            .. fmt(result)
            .. " | Ожидалось: "
            .. fmt(expected)

        if not ok then
            return fail("Ошибка вызова GetTargetInfo: " .. tostring(result))
        end

        if type(result) ~= "string" then
            return fail("Функция должна вернуть строку")
        end

        if normalize(result) ~= normalize(expected) then
            return fail("Вывод функции не совпадает с ожидаемым")
        end

        return true
    end,
}

ns_llua['lua'][73] = {
    type = "commenttest",
    title = "Практика: Массив данных игрока и цели",
    helpModules = {71, 44.1, 57},
    preloadVars = {
        {var = "GetPlayerAndTargetList", desc = "GetPlayerAndTargetList очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "expectedResult", desc = "expectedResult очищается перед проверкой"},
        {var = "testResult", desc = "testResult очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "expectedResult",
        "testResult",
    },
    instruction = [=[
<h>Практика: Массив данных игрока и цели</h>
<t>Создай глобальную функцию <k>GetPlayerAndTargetList()</k>.</t>

<t>Перед проверкой выбери в цель другого игрока.</t>

<t>Функция должна собрать данные о двух юнитах: самом игроке и его текущей цели.</t>

<t>Функция должна вернуть массив из двух строк.</t>

<t>Каждая строка должна содержать информацию об одном юните в формате:</t>
<c>Имя: X, Класс: Y, Токен: Z, Уровень: N</c>

<t>Пример строки:</t>
<s>"Имя: Шеф, Класс: Паладин, Токен: PALADIN, Уровень: 80"</s>

<t>Массив должен быть отсортирован.</t>

<w>Если цели нет или не удалось получить её данные, проверка выдаст предупреждение.</w>

<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function GetPlayerAndTargetList()

end
]=],
    requireKeywords = {
        "GetPlayerAndTargetList",
        "function",
        "player",
        "target",
        "UnitName",
        "UnitClass",
        "UnitLevel",
        "table.sort",
        "return",
    },
    forbidKeywords = {
        "print",
    },
    checkCode = function()
        _G.checkError = nil
        _G.expectedResult = nil
        _G.testResult = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetPlayerAndTargetList) ~= "function" then
            return fail("GetPlayerAndTargetList не является глобальной функцией")
        end

        local function fmt(v)
            if type(v) == "string" then
                return '"' .. v .. '"'
            elseif type(v) == "nil" then
                return "nil"
            elseif type(v) == "boolean" then
                return v and "true" or "false"
            else
                return tostring(v)
            end
        end

        local function normalize(s)
            s = tostring(s)
            s = s:gsub("%s+", " ")
            return s:match("^%s*(.-)%s*$")
        end

        local function getUnitInfo(unit)
            local okExists, exists = pcall(UnitExists, unit)

            if not okExists or not exists then
                return nil
            end

            local okName, name = pcall(UnitName, unit)

            if not okName or type(name) ~= "string" or name == "" then
                return nil
            end

            local okClass, className, classToken = pcall(UnitClass, unit)

            if not okClass
                or type(className) ~= "string"
                or className == ""
                or type(classToken) ~= "string"
                or classToken == "" then
                return nil
            end

            local okLevel, level = pcall(UnitLevel, unit)

            if not okLevel or type(level) ~= "number" then
                return nil
            end

            return string.format(
                "Имя: %s, Класс: %s, Токен: %s, Уровень: %d",
                name,
                className,
                classToken,
                level
            )
        end

        local playerInfo = getUnitInfo("player")

        if not playerInfo then
            return fail("Не удалось получить данные игрока.")
        end

        local targetInfo = getUnitInfo("target")

        if not targetInfo then
            return fail("Нет цели или не удалось получить её данные. Выбери в цель другого игрока и нажми проверку снова.")
        end

        if normalize(playerInfo) == normalize(targetInfo) then
            return fail("Выбери в цель другого игрока, а не самого себя.")
        end

        local expected = {playerInfo, targetInfo}
        table.sort(expected)

        _G.expectedResult = "[1] = " .. fmt(expected[1]) .. " | [2] = " .. fmt(expected[2])

        local ok, result = pcall(_G.GetPlayerAndTargetList)

        if type(result) == "table" then
            _G.testResult = "[1] = " .. fmt(result[1]) .. " | [2] = " .. fmt(result[2])
        else
            _G.testResult = "нет массива"
        end

        if not ok then
            return fail("Ошибка вызова GetPlayerAndTargetList: " .. tostring(result))
        end

        if type(result) ~= "table" then
            return fail("Функция должна вернуть таблицу")
        end

        if #result ~= 2 then
            return fail("В массиве должно быть ровно 2 элемента")
        end

        if type(result[1]) ~= "string" or type(result[2]) ~= "string" then
            return fail("Оба элемента массива должны быть строками")
        end

        if normalize(result[1]) ~= normalize(expected[1]) then
            return fail("Первый элемент массива не совпадает с ожидаемым")
        end

        if normalize(result[2]) ~= normalize(expected[2]) then
            return fail("Второй элемент массива не совпадает с ожидаемым")
        end

        return true
    end,
}

ns_llua['lua'][74] = {
    type = "commenttest",
    title = "Тест 71-4: функция GetPartyHealthTable",
    helpModules = {71, 29, 31, 45},
    preloadVars = {
        {var = "GetPartyHealthTable", desc = "GetPartyHealthTable очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "expectedResult", desc = "expectedResult очищается перед проверкой"},
        {var = "testResult", desc = "testResult очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "expectedResult",
        "testResult",
    },
    instruction = [=[
<h>Тест 71-4: функция GetPartyHealthTable</h>
<t>Создай глобальную функцию <k>GetPartyHealthTable()</k>.</t>

<t>Перед проверкой убедись, что ты состоишь в группе.</t>

<t>Функция должна вернуть хэш-таблицу, где:</t>
<c>ключ</c> — имя члена группы,
<c>значение</c> — его текущий процент здоровья (целое число от 0 до 100).

<t>В таблицу должны попасть сам игрок (<k>player</k>) и все занятые слоты от <k>party1</k> до <k>party4</k>.</t>

<t>Пустые слоты пропускаются и не попадают в таблицу.</t>

<t>Если у юнита максимальное здоровье равно нулю или меньше, его процент считается равным <n>0</n>.</t>

<w>Если ты не в группе, проверка выдаст предупреждение.</w>
<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function GetPartyHealthTable()

end
]=],
    requireKeywords = {
        "GetPartyHealthTable",
        "function",
        "player",
        "party",
        "UnitExists",
        "UnitName",
        "UnitHealth",
        "UnitHealthMax",
        "return",
    },
    forbidKeywords = {
        "print",
    },
    checkCode = function()
        _G.checkError = nil
        _G.expectedResult = nil
        _G.testResult = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetPartyHealthTable) ~= "function" then
            return fail("GetPartyHealthTable не является глобальной функцией")
        end

        local function fmt(v)
            if type(v) == "string" then
                return '"' .. v .. '"'
            elseif type(v) == "nil" then
                return "nil"
            elseif type(v) == "boolean" then
                return v and "true" or "false"
            elseif type(v) == "table" then
                if #v > 0 then
                    local parts = {}
                    for i = 1, #v do
                        parts[i] = fmt(v[i])
                    end
                    return "{" .. table.concat(parts, ", ") .. "}"
                end

                local keys = {}
                for k in pairs(v) do
                    table.insert(keys, k)
                end
                table.sort(keys, function(a, b)
                    return tostring(a) < tostring(b)
                end)

                local parts = {}
                for _, k in ipairs(keys) do
                    table.insert(parts, tostring(k) .. "=" .. fmt(v[k]))
                end
                return "{" .. table.concat(parts, ", ") .. "}"
            else
                return tostring(v)
            end
        end

        -- Строгая валидация числа: отсекает NaN, inf и не-числа
        local function isValidNumber(v)
            if type(v) ~= "number" then
                return false
            end

            if v ~= v then
                return false
            end

            if v == math.huge or v == -math.huge then
                return false
            end

            return true
        end

        local function getPercent(unit)
            local hp = UnitHealth(unit) or 0
            local hpMax = UnitHealthMax(unit) or 0

            if hpMax <= 0 then
                return 0
            end

            return math.floor(hp / hpMax * 100)
        end

        local expected = {}

        local playerName = UnitName("player")
        if playerName then
            expected[playerName] = getPercent("player")
        end

        local partyCount = 0
        for i = 1, 4 do
            local unit = "party" .. i

            if UnitExists(unit) then
                partyCount = partyCount + 1

                local name = UnitName(unit)
                if name then
                    expected[name] = getPercent(unit)
                end
            end
        end

        if partyCount == 0 then
            return fail("Ты не в группе. Собери группу и нажми проверку снова.")
        end

        _G.expectedResult = fmt(expected)

        local ok, result = pcall(_G.GetPartyHealthTable)

        _G.testResult = fmt(result)

        if not ok then
            return fail("Ошибка вызова GetPartyHealthTable: " .. tostring(result))
        end

        if type(result) ~= "table" then
            return fail("Функция должна вернуть таблицу")
        end

        for name, percent in pairs(expected) do
            local value = result[name]

            if value == nil then
                return fail("В таблице нет значения для: " .. name)
            end

            if not isValidNumber(value) then
                return fail("Значение для " .. name .. " не является корректным числом (NaN/inf/не число)")
            end

            if not (value >= 0 and value <= 100) then
                return fail("Процент для " .. name .. " вне диапазона 0-100")
            end

            if not (math.abs(value - percent) <= 1) then
                return fail("Процент здоровья не совпадает для: " .. name)
            end
        end

        for name in pairs(result) do
            if expected[name] == nil then
                return fail("Лишний ключ в таблице: " .. tostring(name))
            end
        end

        return true
    end,
}

ns_llua['lua'][75] = {
    type = "commenttest",
    title = "Тест 71-5: функция IsTargetAnotherPlayer",
    helpModules = {71, 17, 45},
    preloadVars = {
        {var = "IsTargetAnotherPlayer", desc = "IsTargetAnotherPlayer очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "testResult", desc = "testResult очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "testResult",
    },
    instruction = [=[
<h>Тест 71-5: функция IsTargetAnotherPlayer</h>
<t>Создай глобальную функцию <k>IsTargetAnotherPlayer()</k>.</t>

<t>Перед проверкой выбери цель.</t>

<t>Функция должна сравнить имя игрока и имя цели.</t>

<t>Если имена совпадают (цель — сам игрок), функция должна вернуть <k>nil</k>.</t>

<t>Если имена разные, функция должна вернуть <k>true</k>.</t>

<w>Сравнивай именно по имени через UnitName.</w>
<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function IsTargetAnotherPlayer()

end
]=],
    requireKeywords = {
        "IsTargetAnotherPlayer",
        "function",
        "UnitName",
        "player",
        "target",
        "return",
    },
    forbidKeywords = {
        "print",
    },
    checkCode = function()
        _G.checkError = nil
        _G.testResult = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.IsTargetAnotherPlayer) ~= "function" then
            return fail("IsTargetAnotherPlayer не является глобальной функцией")
        end

        local okExists, exists = pcall(UnitExists, "target")

        if not okExists or not exists then
            return fail("Нет цели. Выбери цель и нажми проверку снова.")
        end

        local function fmt(v)
            if type(v) == "string" then
                return '"' .. v .. '"'
            elseif type(v) == "nil" then
                return "nil"
            elseif type(v) == "boolean" then
                return v and "true" or "false"
            else
                return tostring(v)
            end
        end

        local okName1, playerName = pcall(UnitName, "player")
        local okName2, targetName = pcall(UnitName, "target")

        if not okName1 or not okName2 then
            return fail("Не удалось получить имена игрока или цели.")
        end

        local expected

        if playerName == targetName then
            expected = nil
        else
            expected = true
        end

        local ok, result = pcall(_G.IsTargetAnotherPlayer)

        _G.testResult = "Игрок: "
            .. fmt(playerName)
            .. " | Цель: "
            .. fmt(targetName)
            .. " | Получено: "
            .. fmt(result)
            .. " | Ожидалось: "
            .. fmt(expected)

        if not ok then
            return fail("Ошибка вызова IsTargetAnotherPlayer: " .. tostring(result))
        end

        if result ~= expected then
            return fail("Результат не совпадает с ожидаемым")
        end

        return true
    end,
}

ns_llua['lua'][76] = {
    type = "commenttest",
    title = "Практика: Отчёт по классам в рейде",
    helpModules = {71, 44, 44.1, 57},
    preloadVars = {
        {var = "GetRaidClassReport", desc = "GetRaidClassReport очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "expectedResult", desc = "expectedResult очищается перед проверкой"},
        {var = "testResult", desc = "testResult очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "expectedResult",
        "testResult",
    },
    instruction = [=[
<h>Практика: Отчёт по классам в рейде</h>
<t>Создай глобальную функцию <k>GetRaidClassReport()</k>.</t>

<t>Перед проверкой убедись, что ты состоишь в рейде.</t>

<t>Функция должна посчитать, сколько представителей каждого класса есть в рейде, и вернуть одну строку.</t>

<t>Формат каждого элемента:</t>
<s>Класс: N</s>

<t>Элементы должны быть объединены через запятую и пробел.</t>

<t>Классы должны идти в алфавитном порядке.</t>

<t>В строку попадают только те классы, которые реально присутствуют в рейде.</t>

<t>Класс должен быть читаемым (локализованным), а не токеном.</t>

<t>Пример результата:</t>
<s>Воин: 2, Рыцарь смерти: 1, Паладин: 3</s>

<w>Если ты не в рейде, проверка выдаст предупреждение.</w>
<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function GetRaidClassReport()

end
]=],
    requireKeywords = {
        "GetRaidClassReport",
        "function",
        "raid",
        "UnitExists",
        "UnitClass",
        "table.sort",
        "return",
    },
    forbidKeywords = {
        "print",
    },
    checkCode = function()
        _G.checkError = nil
        _G.expectedResult = nil
        _G.testResult = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetRaidClassReport) ~= "function" then
            return fail("GetRaidClassReport не является глобальной функцией")
        end

        local function fmt(v)
            if type(v) == "string" then
                return '"' .. v .. '"'
            elseif type(v) == "nil" then
                return "nil"
            elseif type(v) == "boolean" then
                return v and "true" or "false"
            else
                return tostring(v)
            end
        end

        local function normalize(s)
            s = tostring(s)
            s = s:gsub("%s+", " ")
            return s:match("^%s*(.-)%s*$")
        end

        local counts = {}
        local total = 0

        for i = 1, 40 do
            local unit = "raid" .. i

            if UnitExists(unit) then
                total = total + 1

                local okClass, className = pcall(UnitClass, unit)

                if okClass and type(className) == "string" and className ~= "" then
                    counts[className] = (counts[className] or 0) + 1
                end
            end
        end

        if total == 0 then
            return fail("Ты не в рейде. Собери рейд и нажми проверку снова.")
        end

        local keys = {}
        for k in pairs(counts) do
            table.insert(keys, k)
        end
        table.sort(keys)

        local parts = {}
        for _, k in ipairs(keys) do
            table.insert(parts, k .. ": " .. counts[k])
        end

        local expected = table.concat(parts, ", ")

        _G.expectedResult = fmt(expected)

        local ok, result = pcall(_G.GetRaidClassReport)

        _G.testResult = fmt(result)

        if not ok then
            return fail("Ошибка вызова GetRaidClassReport: " .. tostring(result))
        end

        if type(result) ~= "string" then
            return fail("Функция должна вернуть строку")
        end

        if normalize(result) ~= normalize(expected) then
            return fail("Строка не совпадает с ожидаемой")
        end

        return true
    end,
}

ns_llua['lua'][77] = {
    type = "info",
    title = "UnitGUID: уникальный идентификатор юнита",
    content = [=[
<h>Что такое GUID</h>
<t>GUID — это уникальный идентификатор юнита в WoW. Он есть у игроков, NPC, мобов, питомцев и игровых объектов.</t>
<t>GUID возвращается как строка. Обычно она выглядит как шестнадцатеричное число с префиксом <s>0x</s>, например:</t>
<s>0x0000000000000001</s>

<h>Как получить GUID</h>
<t>GUID узнают через WoW API функцию <k>UnitGUID</k>.</t>
<t>В скобках передают идентификатор юнита.</t>
<t>Примеры идентификаторов:</t>
<t>- <s>"player"</s> — твой персонаж;</t>
<t>- <s>"target"</s> — текущая цель;</t>
<t>- <s>"focus"</s> — фокус;</t>
<t>- <s>"party1"</s> — первый участник группы;</t>
<t>- <s>"raid1"</s> — первый участник рейда.</t>

<code>
/run print(UnitGUID("player"))
/run print(UnitGUID("target"))
</code>

<t>Если юнит существует, функция вернёт строку GUID.</t>
<w>Если юнита нет, функция вернёт <k>nil</k>.</w>

<h>Как читать GUID</h>
<t>Фактически это 64-битное число, записанное в шестнадцатеричном виде.</t>
<t>Старшие символы GUID показывают тип объекта: игрок, существо, питомец или игровой объект.</t>
<t>У существ внутри GUID также зашит шаблон (entry), а младшие разряды — уникальный номер конкретного спауна.</t>

<h>Игрок или моб</h>
<t>Для практических задач игроков и мобов удобно различать по началу GUID.</t>
<t>У игроков GUID начинается с <s>"0x0000"</s>.</t>
<t>У мобов и NPC начало GUID другое.</t>
<t>Поэтому простое правило такое: если начало GUID равно <s>"0x0000"</s>, считаем юнита игроком. Иначе считаем его мобом.</t>
<w>В этом курсе для упрощения делим цель только на два типа: игрок и моб.</w>

<h>Постоянство GUID</h>
<t>У игроков GUID постоянный и привязан к персонажу.</t>
<t>У боссов и ключевых NPC GUID обычно тоже не меняется.</t>
<t>У рядовых мобов GUID может пересоздаваться после рестарта сервера.</t>
<t>Поэтому GUID надёжен для игроков и боссов, но не всегда надёжен для обычных мобов между рестартами.</t>
]=],
}

ns_llua['lua'][78] = {
    type = "commenttest",
    title = "Тест 77-1: функция GetTargetType",
    helpModules = {77, 21.2, 45},
    preloadVars = {
        {var = "GetTargetType", desc = "GetTargetType очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "testResult", desc = "testResult очищается перед проверкой"},
    },
    reportVars = {"checkError", "testResult"},
    instruction = [=[
<h>Тест 77-1: функция GetTargetType</h>
<t>Создай глобальную функцию <k>GetTargetType()</k>.</t>
<t>Перед проверкой выдели цель: игрока или моба.</t>
<t>Функция должна вернуть строку:</t>
<t>- <s>"игрок"</s>, если цель — игрок;</t>
<t>- <s>"моб"</s>, если цель не игрок.</t>
<t>Обязательно используй операторы <k>and</k> и <k>or</k>.</t>
<w>Запрещено использовать <k>if</k>.</w>
<w>Если цели нет, проверка выдаст предупреждение.</w>
<w>Функция должна вернуть значение, а не печатать его.</w>
]=],
    initialCode = [=[
function GetTargetType()

end
]=],
    requireKeywords = {
        "GetTargetType",
        "function",
        "target",
        "UnitGUID",
        "and",
        "or",
        "return",
    },
    forbidKeywords = {
        "if",
    },
    checkCode = function()
        _G.checkError = nil
        _G.testResult = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetTargetType) ~= "function" then
            return fail("GetTargetType не является глобальной функцией")
        end

        local okExists, exists = pcall(UnitExists, "target")
        if not okExists or not exists then
            return fail("Нет цели. Выдели игрока или моба и нажми проверку снова.")
        end

        local okGuid, guid = pcall(UnitGUID, "target")
        if not okGuid or type(guid) ~= "string" then
            return fail("Не удалось получить GUID цели.")
        end

        local expected = string.sub(guid, 1, 6) == "0x0000" and "игрок" or "моб"

        local ok, result = pcall(_G.GetTargetType)
        _G.testResult = "Получено: " .. tostring(result) .. " | Ожидалось: " .. expected

        if not ok then
            return fail("Ошибка вызова GetTargetType: " .. tostring(result))
        end

        if type(result) ~= "string" then
            return fail('Функция должна вернуть строку: "игрок" или "моб"')
        end

        if result ~= expected then
            return fail("Результат не совпадает с ожидаемым")
        end

        return true
    end,
}

ns_llua['lua'][79] = {
    type = "info",
    title = "Отладка через print",
    content = [=[
<h>Отладка через print</h>
<t><k>print</k> — это быстрый способ заглянуть внутрь кода и понять, что реально происходит.</t>
<t>Принты можно ставить почти где угодно: в начале функции, внутри цикла, перед условием, перед return.</t>

<h>Что можно узнавать через print</h>
<t>- что пришло в функцию;</t>
<t>- какого типа аргумент;</t>
<t>- сколько элементов в таблице;</t>
<t>- что лежит внутри таблицы;</t>
<t>- что вернула WoW API функция;</t>
<t>- какие значения получаются перед return.</t>

<h>Простой вывод</h>
<code>
print("Привет")
print(123)
print(nil)
</code>

<t>В <k>print</k> можно передавать несколько значений через запятую.</t>
<code>
local x = 7
print("x =", x)
print("тип x =", type(x))
print("x и тип:", x, type(x))
</code>

<w>Совет:</w> для отладки часто безопаснее использовать запятые, а не склейку через <k>..</k>.
<code>
-- Может упасть, если value равно nil
print("value: " .. value)

-- Обычно безопаснее
print("value:", value)
</code>

<h>print внутри функции</h>
<t>Если функция ведёт себя странно, первым делом можно вывести её аргументы.</t>
<code>
function Example(data)
    print("data =", data, "type =", type(data))
    return data
end
</code>

<h>Отладка таблицы</h>
<t>Если в функцию приходит таблица, можно вывести её длину и элементы.</t>
<code>
function ShowTable(t)
    if type(t) ~= "table" then
        print("Это не таблица:", t, type(t))
        return
    end

    print("Длина таблицы:", #t)

    for i, v in ipairs(t) do
        print(i, v, type(v))
    end
end
</code>

<h>Отладка WoW API</h>
<t>Если ты используешь API-функцию, например <k>UnitGUID</k>, можно вывести и сам аргумент, и результат.</t>
<code>
local guid = UnitGUID(unit)
print("unit:", unit)
print("guid:", guid)
</code>

<t>Если результат <k>nil</k>, это тоже важная информация: значит, юнита нет, либо аргумент был некорректным.</t>

<h>Отладка перед return</h>
<t>Перед возвратом результата полезно вывести то, что функция реально возвращает.</t>
<code>
print("result:", players, mobs, garbage)
return players, mobs, garbage
</code>

<h>Принты в проверке заданий</h>
<t>В commenttest принты, которые выполняются во время проверки, попадают в отчёт.</t>
<t>Если проверка не проходит, добавь <k>print</k> внутрь функции и нажми проверку снова.</t>
<t>Так можно увидеть:</t>
<t>- какие входные данные реально подаются;</t>
<t>- какие из них ломают код;</t>
<t>- где именно функция считает неправильно.</t>

<w>Не бойся временно ставить много принтов.</w>
<t>Сначала найди проблему, потом убери лишнее.</t>
]=],
}

ns_llua['lua'][80] = {
    type = "commenttest",
    title = "Тест: функция CountUnitTypes",
    helpModules = {79, 77, 45},
    preloadVars = {
        {var = "CountUnitTypes", desc = "CountUnitTypes очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
        {var = "test5", desc = "test5 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
        "test5",
    },
    instruction = [=[
<h>Тест: функция CountUnitTypes</h>
<t>Создай глобальную функцию <k>CountUnitTypes(units)</k>.</t>
<t>Во время проверки функция будет получать разные входные данные.</t>
<t>Функция должна вернуть три числа:</t>
<t>1. количество игроков;</t>
<t>2. количество мобов;</t>
<t>3. количество мусора.</t>
<w>Перед проверкой обязательно возьми в цель моба или NPC. Цель не должна быть игроком.</w>
<t>Если не понятно, что приходит в функцию или почему тест не проходит, используй <k>print</k> внутри функции.</t>
<h>Бонус за компактность</h>
<t>- код 555 символов или меньше — 2 опыта и 300 репутации;</t>
<t>- код 500 символов или меньше — 3 опыта и 500 репутации.</t>
<t>Символы считаются вместе с пробелами и переносами строк.</t>
]=],
    initialCode = [=[
function CountUnitTypes(units)

end
]=],
    requireKeywords = {
        "CountUnitTypes",
        "function",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        for i = 1, 5 do
            _G["test" .. i] = nil
        end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.CountUnitTypes) ~= "function" then
            return fail("CountUnitTypes не является глобальной функцией")
        end

        local okExists, exists = pcall(UnitExists, "target")
        if not okExists or not exists then
            return fail("Нет цели. Возьми в цель моба или NPC и нажми проверку снова.")
        end

        local okGuid, guid = pcall(UnitGUID, "target")
        if not okGuid or type(guid) ~= "string" then
            return fail("Не удалось получить GUID цели.")
        end

        if string.sub(guid, 1, 6) == "0x0000" then
            return fail("Цель не должна быть игроком. Возьми в цель моба или NPC.")
        end

        local function getExpected(units)
            local players = 0
            local mobs = 0
            local garbage = 0

            if type(units) ~= "table" then
                return players, mobs, garbage
            end

            for _, unit in ipairs(units) do
                local unitGuid

                if type(unit) == "string" then
                    local ok, result = pcall(UnitGUID, unit)
                    if ok and type(result) == "string" then
                        unitGuid = result
                    end
                end

                if type(unitGuid) ~= "string" then
                    garbage = garbage + 1
                elseif string.sub(unitGuid, 1, 6) == "0x0000" then
                    players = players + 1
                else
                    mobs = mobs + 1
                end
            end

            return players, mobs, garbage
        end

        local tests = {
            {input = {"player", "target", "focus", "ns_invalid", "123"}},
            {input = {"player", "player"}},
            {input = {"", "bad", "123", 7, true}},
            {input = {}},
            {input = "bad"},
        }

        for i, test in ipairs(tests) do
            local expPlayers, expMobs, expGarbage = getExpected(test.input)
            local ok, players, mobs, garbage = pcall(_G.CountUnitTypes, test.input)

            if not ok then
                _G["test" .. i] = "Ошибка: " .. tostring(players)
                    .. " | Ожидалось: players=" .. tostring(expPlayers)
                    .. ", mobs=" .. tostring(expMobs)
                    .. ", garbage=" .. tostring(expGarbage)
                return fail("Тест " .. i .. " не пройден")
            end

            _G["test" .. i] = "Получено: players=" .. tostring(players)
                .. ", mobs=" .. tostring(mobs)
                .. ", garbage=" .. tostring(garbage)
                .. " | Ожидалось: players=" .. tostring(expPlayers)
                .. ", mobs=" .. tostring(expMobs)
                .. ", garbage=" .. tostring(expGarbage)

            if players ~= expPlayers or mobs ~= expMobs or garbage ~= expGarbage then
                return fail("Тест " .. i .. " не пройден")
            end
        end

        return true
    end,
}

ns_llua['lua'][81] = {
    type = "commenttest",
    title = "Тест: функция BuildGUIDReport",
    helpModules = {77, 31, 44, 7},
    preloadVars = {
        {var = "BuildGUIDReport", desc = "BuildGUIDReport очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4"},
    instruction = [=[
<h>Тест функция BuildGUIDReport</h>
<t>Создай глобальную функцию <k>BuildGUIDReport(units)</k>.</t>
<t>Аргумент <k>units</k> — хэш-таблица: ключ — имя юнита, значение — его GUID.</t>
<t>Функция должна вернуть одну строку с записью по каждому юниту.</t>
<t>Формат записи: <s>"имя: игрок"</s> или <s>"имя: моб"</s>.</t>
<t>Записи соединяются через запятую и пробел. Порядок записей может быть любым.</t>
<t>Если аргумент не таблица или таблица пустая, верни пустую строку.</t>
<t>Пример:</t>
<code>
local map = {
    ["Шеф"] = "0x0000000000184817",
    ["Тралл"] = "0xF1300013550015F4",
}
BuildGUIDReport(map) -- "Шеф: игрок, Тралл: моб" (порядок может быть любым)
</code>
<w>Ничего выводить не нужно.</w>
<h>Бонус за компактность</h>
<t>Если код будет 260 символов или меньше — получишь бонусную награду.</t>
]=],
    initialCode = [=[
function BuildGUIDReport(units)

end
]=],
    requireKeywords = {
        "BuildGUIDReport",
        "function",
        "pairs",
        "and",
        "or",
        "return",
        "0x0000",
    },
    forbidKeywords = {
        "print",
    },
    checkCode = function()
        _G.checkError = nil
        for i = 1, 4 do
            _G["test" .. i] = nil
        end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.BuildGUIDReport) ~= "function" then
            return fail("BuildGUIDReport не является глобальной функцией")
        end

        local realList = {
            ["Шеф"] = "0x0000000000184817",
            ["Воинствующая"] = "0x000000000021361F",
            ["Тренировочный манекен PvP"] = "0xF13000EA650012DE",
            ["Гипотеза"] = "0x00000000004755A5",
            ["Кернаг"] = "0x00000000001E196C",
            ["Импресарио"] = "0xF13002E668001395",
            ["Высшая"] = "0x00000000001E409C",
            ["Оргримарский рубака"] = "0xF130000CE0000D4B",
            ["Тралл"] = "0xF1300013550015F4",
            ["Кровопалый кнутохвост"] = "0xF130000C320031EF",
        }

        local function getExpected(map)
            local set = {}
            local count = 0
            if type(map) ~= "table" then
                return set, count
            end
            for name, guid in pairs(map) do
                if type(name) == "string" and type(guid) == "string" then
                    local kind = string.sub(guid, 1, 6) == "0x0000" and "игрок" or "моб"
                    set[name .. ": " .. kind] = true
                    count = count + 1
                end
            end
            return set, count
        end

        local function parseResult(s)
            local set = {}
            local count = 0
            for part in s:gmatch("[^,]+") do
                local entry = part:match("^%s*(.-)%s*$")
                if entry ~= "" then
                    set[entry] = true
                    count = count + 1
                end
            end
            return set, count
        end

        local function fmtSet(set)
            local keys = {}
            for k in pairs(set) do
                table.insert(keys, k)
            end
            table.sort(keys)
            return table.concat(keys, ", ")
        end

        local tests = {
            {input = realList},
            {input = {["Шеф"] = "0x0000000000184817", ["Тралл"] = "0xF1300013550015F4"}},
            {input = {}},
            {input = "bad"},
        }

        for i, test in ipairs(tests) do
            local expSet, expCount = getExpected(test.input)
            local ok, result = pcall(_G.BuildGUIDReport, test.input)

            _G["test" .. i] = "Получено: " .. tostring(result)
                .. " | Ожидалось (в любом порядке): " .. fmtSet(expSet)

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова функции")
            end

            if type(result) ~= "string" then
                return fail("Тест " .. i .. ": функция должна вернуть строку")
            end

            local resSet, resCount = parseResult(result)

            if resCount ~= expCount then
                return fail("Тест " .. i .. " не пройден")
            end

            for k in pairs(expSet) do
                if not resSet[k] then
                    return fail("Тест " .. i .. " не пройден")
                end
            end
        end

        return true
    end,
}

ns_llua['lua'][82] = {
    type = "info",
    title = "Структура GUID: entry моба и Wowhead",
    helpModules = {77, 10},
    content = [=[
<h>Что внутри GUID</h>
<t>GUID в WoW 3.3.5 — это 64-битное число в шестнадцатеричном виде. Префикс <s>0x</s> и 16 цифр:</t>
<s>0xF1300013550015F4</s>

<t>Разобьём строку на части по смыслу:</t>

<t><k>0x</k> — префикс, обозначающий шестнадцатеричное число. Есть у всех GUID.</t>
<t><k>F130</k> (4 символа) — тип объекта. Определяет, что это: игрок, существо, питомец или игровой объект.</t>
<t><k>00</k> (2 символа) — регион или инстанс. Техническая информация о мире, где находится юнит.</t>
<t><k>1355</k> (4 символа) — entry. ID шаблона NPC. У всех спаунов одного моба эта часть одинаковая.</t>
<t><k>0015F4</k> (6 символов) — номер спауна. Уникальный идентификатор конкретного экземпляра.</t>

<t>Самое полезное поле — <k>entry</k> (символы 9–12). Это ID шаблона NPC, одинаковый у всех спаунов одного и того же моба.</t>

<h>Пример: Тралл</h>
<t>У Тралла GUID: <s>0xF1300013550015F4</s>. Символы 9–12: <s>1355</s>.</t>
<t>Это шестнадцатеричное число. Чтобы превратить его в привычное десятичное, используем <k>tonumber</k> со вторым аргументом — основанием системы счисления:</t>

<code>
print(tonumber("1355", 16)) -- 4949
</code>

<t>Получилось <n>4949</n>. Это и есть ID Тралла как NPC.</t>

<h>Ссылка на Wowhead</h>
<t>Зная entry, можно сразу открыть страницу моба:</t>
<s>https://www.wowhead.com/classic/ru/npc=4949</s>

<t>Для любого моба склейка одна и та же:</t>
<code>
local guid = UnitGUID("target")
local entry = tonumber(string.sub(guid, 9, 12), 16)
local url = "https://www.wowhead.com/classic/ru/npc=" .. entry
print(url)
</code>

<h>Проверка на других мобах</h>
<t>Оргриммарский рубака: GUID <s>0xF130000CE0000D4B</s>, entry <s>00CE</s>:</t>
<code>
print(tonumber("00CE", 16)) -- 206
-- https://www.wowhead.com/classic/ru/npc=206
</code>

<t>Кровопалый кнутохвост: GUID <s>0xF130000C320031EF</s>, entry <s>00C3</s>:</t>
<code>
print(tonumber("00C3", 16)) -- 195
-- https://www.wowhead.com/classic/ru/npc=195
</code>

<h>Важно про игроков</h>
<t>У игроков GUID начинается с <s>0x0000</s> — это совсем другая структура, и entry у них нет. Вытаскивать символы 9–12 имеет смысл только когда ты уже убедился, что это не игрок:</t>

<code>
local guid = UnitGUID("target")
if string.sub(guid, 1, 6) == "0x0000" then
    print("Это игрок, entry тут нет")
else
    local entry = tonumber(string.sub(guid, 9, 12), 16)
    print("NPC entry:", entry)
end
</code>

<h>Почему одинаковые мобы дают разные GUID</h>
<t>Два спауна одного и того же Оргриммарского рубаки будут иметь одинаковый entry (<n>206</n>), но разный номер спауна в последних символах. Поэтому сравнивать GUID целиком нельзя — сравнивай только entry.</t>

<h>Короткое правило</h>
<c>entry = tonumber(guid:sub(9, 12), 16)</c>
<c>url = "https://www.wowhead.com/classic/ru/npc=" .. entry</c>
]=],
}

ns_llua['lua'][83] = {
type = "info",
title = "Ресурсы юнита: мана, ярость, энергия",
helpModules = {65, 71, 7},
content = [=[
<h>Ресурсы юнита</h>
<t>Здоровье и безопасные шаблоны мы разобрали в модуле 65. Здесь — то, что есть у юнита кроме здоровья: мана, ярость, энергия, руническая сила.</t>
<t>Ресурс читается той же парой функций, что и здоровье:</t>
<c>UnitMana(unit)</c> — текущий ресурс.
<c>UnitManaMax(unit)</c> — максимальный ресурс.
<code>
-- UnitMana("player") — текущий ресурс персонажа (мана, ярость или энергия)
-- UnitManaMax("player") — потолок этого ресурса
-- print выведет оба значения через табуляцию, например: 12500 15000
/run print(UnitMana("player"), UnitManaMax("player"))
</code>
<t>Функция возвращает основной ресурс класса: у мага — ману, у воина — ярость, у разбойника — энергию.</t>
<t>Если ресурса у класса нет (у воина нет маны), <k>UnitManaMax</k> вернёт <n>0</n>. Поэтому правило из модуля 65 то же: перед делением проверяй знаменатель.</t>
<h>Тип ресурса: UnitPowerType</h>
<code>
-- UnitPowerType возвращает СРАЗУ два значения:
-- 1-е — числовой код типа ресурса (0 — мана, 1 — ярость, 3 — энергия и т.д.)
-- 2-е — строковый токен ("MANA", "RAGE", "ENERGY" и т.д.)
-- print выведет оба: например 0 MANA
/run print(UnitPowerType("player"))
</code>
<t>Функция возвращает два значения: числовой код и строковый токен.</t>
<t>Для логики удобнее токен: <s>"MANA"</s>, <s>"RAGE"</s>, <s>"ENERGY"</s>, <s>"RUNIC_POWER"</s>.</t>
<code>
-- Первый результат (числовой код) нам не нужен,
-- поэтому вместо переменной стоит _ — это общепринятая "дырка" для ненужного значения
-- Второй результат (токен) сохраняем в token и выводим
/run local _, token = UnitPowerType("player"); print(token)
</code>
<h>Знак процента в string.format</h>
<t>Чтобы вывести сам знак процента, в шаблоне пишут <k>%%</k> — два процента схлопываются в один при выводе.</t>
<code>
-- hp — текущее здоровье; or 0 подстраховка: если API вернул nil, возьмём 0
-- hpMax — максимальное здоровье; та же страховка от nil
-- if hpMax > 0 — защита от деления на ноль: делим только при положительном знаменателе
-- внутри string.format: %d — место под целое число, %% — один % в выводе
-- math.floor(hp / hpMax * 100) — процент здоровья, округлённый вниз
/run local hp = UnitHealth("player") or 0; local hpMax = UnitHealthMax("player") or 0; if hpMax > 0 then print(string.format("HP: %d/%d (%d%%)", hp, hpMax, math.floor(hp / hpMax * 100))) end
</code>
<h>Безопасный отчёт по ресурсу</h>
<t>Безопасный шаблон из модуля 65 работает и для ресурсов. Та же идея для маны, сразу с красивой строкой:</t>
<code>
function GetManaReport(unit)
    -- Если юнита не существует (нет цели, опечатка в unitID),
    -- дальше считать нечего: выходим из функции досрочно с текстом
    if not UnitExists(unit) then
        return "Нет юнита"
    end
    -- Текущий ресурс юнита; or 0 — если API вернул nil, подставляем 0
    local mana = UnitMana(unit) or 0
    -- Максимальный ресурс; та же страховка от nil
    local manaMax = UnitManaMax(unit) or 0
    -- Если максимум равен 0 (у воина нет маны), делить нельзя:
    -- выходим досрочно с текстом вместо числа
    if manaMax <= 0 then
        return "Нет ресурса"
    end
    -- Собираем строку вида "12500/15000 (83%)":
    -- первый %d — текущий ресурс, второй %d — максимум,
    -- %d%% — процент и знак процента (%% даёт один % в выводе),
    -- math.floor(mana / manaMax * 100) — процент ресурса, округлённый вниз
    return string.format("%d/%d (%d%%)", mana, manaMax, math.floor(mana / manaMax * 100))
end
</code>
<t>Это заготовка для будущих тестов: безопасные проверки из 65 плюс <k>%%</k> из этого модуля.</t>
]=],
}

ns_llua['lua'][84] = {
type = "commenttest",
title = "Тест 83-1: функция GetResourceLine",
helpModules = {83, 65, 7},
preloadVars = {
{var = "GetResourceLine", desc = "GetResourceLine очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
{var = "test1", desc = "test1 очищается перед проверкой"},
},
reportVars = {"checkError", "test1"},
instruction = [=[
<h>Тест 83-1: функция GetResourceLine</h>
<t>Создай глобальную функцию <k>GetResourceLine(unit)</k>.</t>
<t>Перед проверкой возьми в цель любого юнита: игрока или моба.</t>
<t>Проверка вызовет функцию с аргументом <k>"target"</k> и сравнит результат с данными твоей текущей цели.</t>
<t>Если юнит существует и у него есть ресурс, верни строку в формате:</t>
<s>"MANA: 12500/15000 (83%)"</s>
<t>Первое слово — тип ресурса юнита: второй результат <k>UnitPowerType(unit)</k> через <k>select(2, ...)</k>.</t>
<t>Если юнита нет или максимальный ресурс равен 0, верни строку <s>"Нет ресурса"</s>.</t>
<t>Используй <k>UnitMana</k>, <k>UnitManaMax</k>, <k>math.floor</k> и <k>string.format</k>; знак процента в шаблоне пишется как <k>%%</k>.</t>
<w>Ничего выводить не нужно.</w>
]=],
initialCode = [=[
function GetResourceLine(unit)

end
]=],
requireKeywords = {
"GetResourceLine",
"UnitPowerType(unit)",
"function",
"UnitMana(unit)",
"UnitManaMax(unit)",
"return",
},
checkCode = function()
_G.checkError = nil
_G.test1 = nil

local function fail(msg)
_G.checkError = msg
return msg
end

if type(_G.GetResourceLine) ~= "function" then
return fail("GetResourceLine не является глобальной функцией")
end

local okExists, exists = pcall(UnitExists, "target")
if not okExists or not exists then
return fail("Нет цели. Возьми в цель любого юнита и нажми проверку снова.")
end

local function liveValues(unit)
if not UnitExists(unit) then
return nil
end
local max = UnitManaMax(unit) or 0
if max <= 0 then
return nil
end
return UnitMana(unit) or 0, max
end

local function expectedLine(unit)
local cur, max = liveValues(unit)
if cur == nil then
return "Нет ресурса"
end
local _, token = UnitPowerType(unit)
return string.format("%s: %d/%d (%d%%)", tostring(token), cur, max, math.floor(cur / max * 100))
end

local function parseLine(line)
if type(line) ~= "string" then
return nil
end
-- Убираем скобки из строки, чтобы не экранировать их в паттерне
local flat = line:gsub("[()]", "")
local token, cur, max, pct = flat:match("^([^:]+): (%d+)/(%d+) (%d+)%%$")
if not token then
return nil
end
return token, tonumber(cur), tonumber(max), tonumber(pct)
end

local function checkUnit(unit, i)
local ok, result = pcall(_G.GetResourceLine, unit)

-- Заполняем отчёт ДО проверок, чтобы он был виден и при успехе
_G["test" .. i] = "Получено: " .. tostring(result) .. " | Ожидалось: " .. expectedLine(unit)

if not ok then
return fail("Ошибка вызова GetResourceLine('" .. unit .. "'): " .. tostring(result))
end
local cur, max = liveValues(unit)
if cur == nil then
if result ~= "Нет ресурса" then
return fail("Для '" .. unit .. "' ожидалось 'Нет ресурса'")
end
return true
end
local token, rCur, rMax, rPct = parseLine(result)
if not token then
return fail("Строка для '" .. unit .. "' не похожа на 'ТИП: X/Y (P%)'")
end
local _, expToken = UnitPowerType(unit)
if token ~= expToken then
return fail("В строке для '" .. unit .. "' должен быть тип ресурса '" .. tostring(expToken) .. "'")
end
local tol = math.max(5, math.floor(max * 0.05))
if rMax ~= max then
return fail("Максимум ресурса для '" .. unit .. "' не совпадает")
end
if math.abs(rCur - cur) > tol then
return fail("Текущий ресурс для '" .. unit .. "' не совпадает")
end
if rPct ~= math.floor(rCur / rMax * 100) then
return fail("Процент для '" .. unit .. "' не совпадает с дробью X/Y")
end
return true
end

for i, unit in ipairs({"target"}) do
local err = checkUnit(unit, i)
if err ~= true then
return err
end
end

return true
end,
}

ns_llua['lua'][85] = {
type = "commenttest",
title = "Тест 83-2: функция GetResourceName",
helpModules = {83, 45},
preloadVars = {
{var = "GetResourceName", desc = "GetResourceName очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 83-2: функция GetResourceName</h>
<t>Создай глобальную функцию <k>GetResourceName(unit)</k>.</t>
<t>Перед проверкой возьми в цель любого юнита: игрока или моба.</t>
<t>Функция должна узнать, какой у юнита ресурс, и вернуть его название по-русски. Тип ресурса приходит строкой на английском:</t>
<t>- <s>"MANA"</s> — вернуть <s>"мана"</s>;</t>
<t>- <s>"RAGE"</s> — вернуть <s>"ярость"</s>;</t>
<t>- <s>"ENERGY"</s> — вернуть <s>"энергия"</s>;</t>
<t>- <s>"RUNIC_POWER"</s> — вернуть <s>"руническая сила"</s>;</t>
]=],
initialCode = [=[
function GetResourceName(unit)

end
]=],
requireKeywords = {
"function",
"UnitPowerType",
"return",
},
checkCode = function()
_G.checkError = nil

local function fail(msg)
_G.checkError = msg
return msg
end

if type(_G.GetResourceName) ~= "function" then
return fail("GetResourceName не является глобальной функцией")
end

local okExists, exists = pcall(UnitExists, "target")
if not okExists or not exists then
return fail("Нет цели. Возьми в цель любого юнита и нажми проверку снова.")
end

local function rusToken(token)
if token == "MANA" then
return "мана"
elseif token == "RAGE" then
return "ярость"
elseif token == "ENERGY" then
return "энергия"
elseif token == "RUNIC_POWER" then
return "руническая сила"
end
return "другое"
end

local function expected(unit)
local _, token = UnitPowerType(unit)
return rusToken(token)
end

for _, unit in ipairs({"player", "target"}) do
local ok, result = pcall(_G.GetResourceName, unit)
if not ok then
return fail("Ошибка вызова GetResourceName('" .. unit .. "'): " .. tostring(result))
end
if result ~= expected(unit) then
return fail("Для '" .. unit .. "' ожидалось '" .. expected(unit) .. "', получено '" .. tostring(result) .. "'")
end
end

return true
end,
}

ns_llua['lua'][86] = {
    type = "commenttest",
    title = "Тест 83-3: функция CompareResourcePercent",
    helpModules = {83, 65, 21.2, 45},
    preloadVars = {
        {var = "CompareResourcePercent", desc = "CompareResourcePercent очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
        {var = "test5", desc = "test5 очищается перед проверкой"},
        {var = "test6", desc = "test6 очищается перед проверкой"},
        {var = "test7", desc = "test7 очищается перед проверкой"},
    },
    reportVars = {
        "checkError",
        "test1",
        "test2",
        "test3",
        "test4",
        "test5",
        "test6",
        "test7",
    },
    instruction = [=[
<h>Тест 83-3: функция CompareResourcePercent</h>
<t>Создай глобальную функцию <k>CompareResourcePercent(unitA, unitB)</k>.</t>

<t>Функция получает два идентификатора юнита, например:</t>
<c>player</c>
<c>target</c>
<c>focus</c>
<c>pet</c>

<t>Для каждого юнита нужно посчитать процент ресурса:</t>
<c>UnitMana(unit) / UnitManaMax(unit) * 100</c>

<t>Если юнит не существует, процент считается равным 0.</t>
<t>Если максимальный ресурс равен 0 или меньше, процент тоже считается равным 0.</t>

<t>Функция должна вернуть одну строку:</t>
<c>"A" — если процент первого юнита больше;</c>
<c>"B" — если процент второго юнита больше;</c>
<c>"same" — если проценты равны.</c>

<t>Во время проверки система подставит свои тестовые значения для <k>UnitExists</k>, <k>UnitMana</k> и <k>UnitManaMax</k>.</t>
<t>Поэтому брать цель или искать конкретного юнита не нужно.</t>
]=],
    initialCode = [=[
function CompareResourcePercent(unitA, unitB)

end
]=],
    requireKeywords = {
        "CompareResourcePercent",
        "function",
        "UnitExists",
        "UnitMana",
        "UnitManaMax",
        "return",
    },

    -- Моки, подставляемые в изолированное окружение.
    -- _G не трогается, taint не появляется.
    mockGlobals = {
        UnitExists = function(unit)
            local mock = {
                player  = true,
                target  = true,
                boss    = true,
                empty   = true,
                missing = false,
            }

            return mock[unit] == true
        end,

        UnitMana = function(unit)
            local mock = {
                player  = 50,
                target  = 25,
                boss    = 80,
                empty   = 0,
                missing = 0,
            }

            return mock[unit] or 0
        end,

        UnitManaMax = function(unit)
            local mock = {
                player  = 100,
                target  = 100,
                boss    = 200,
                empty   = 0,
                missing = 0,
            }

            return mock[unit] or 0
        end,
    },

    checkCode = function(env)
        _G.checkError = nil

        for i = 1, 7 do
            _G["test" .. i] = nil
        end

        if type(env) ~= "table" then
            _G.checkError = "Внутренняя ошибка: окружение не передано"
            return _G.checkError
        end

        local fn = env.CompareResourcePercent

        if type(fn) ~= "function" then
            _G.checkError = "CompareResourcePercent не является глобальной функцией"
            return _G.checkError
        end

        local mock = {
            player  = {exists = true,  cur = 50, max = 100},
            target  = {exists = true,  cur = 25, max = 100},
            boss    = {exists = true,  cur = 80, max = 200},
            empty   = {exists = true,  cur = 0,  max = 0},
            missing = {exists = false, cur = 0,  max = 0},
        }

        local function mockPercent(unit)
            local data = mock[unit]

            if type(data) ~= "table" or data.exists ~= true then
                return 0
            end

            local max = data.max or 0

            if max <= 0 then
                return 0
            end

            return (data.cur or 0) / max * 100
        end

        local function fmtPct(value)
            return string.format("%.1f%%", value)
        end

        local tests = {
            {"player", "target"},
            {"target", "player"},
            {"boss", "player"},
            {"player", "boss"},
            {"empty", "player"},
            {"missing", "player"},
            {"player", "player"},
        }

        local details = {}
        local allOk = true

        for i, test in ipairs(tests) do
            local unitA = test[1]
            local unitB = test[2]

            local percentA = mockPercent(unitA)
            local percentB = mockPercent(unitB)

            local expected

            if math.abs(percentA - percentB) < 0.001 then
                expected = "same"
            elseif percentA > percentB then
                expected = "A"
            else
                expected = "B"
            end

            local ok, result = pcall(fn, unitA, unitB)

            local resultText

            if ok then
                resultText = tostring(result)
            else
                resultText = "ошибка: " .. tostring(result)
            end

            _G["test" .. i] = string.format(
                "%s vs %s | A=%s, B=%s | Получено: %s | Ожидалось: %s",
                unitA,
                unitB,
                fmtPct(percentA),
                fmtPct(percentB),
                resultText,
                expected
            )

            if not ok or result ~= expected then
                allOk = false
                table.insert(details, _G["test" .. i])
            end
        end

        if not allOk then
            _G.checkError = "Проверка результата не пройдена"
            return table.concat(details, "\n")
        end

        return true
    end,
}

ns_llua['lua'][87] = {
    type = "commenttest",
    title = "Тест 83-4: функция BuildResourceMap",
    helpModules = {83, 65, 31, 44, 45},
    preloadVars = {
        {var = "BuildResourceMap", desc = "BuildResourceMap очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4"},
    instruction = [=[
<h>Тест 83-4: функция BuildResourceMap</h>
<t>Создай глобальную функцию <k>BuildResourceMap(units)</k>.</t>
<t>Перед проверкой возьми в цель любого юнита: игрока или моба.</t>
<t>Аргумент <k>units</k> — массив строк UnitID.</t>
<t>Функция должна вернуть хэш-таблицу: ключ — UnitID, значение — процент ресурса этого юнита (целое число от 0 до 100 через <k>math.floor</k>).</t>
<t>Если юнита нет или у него нет ресурса, значение для него — <n>0</n>.</t>
<t>Если аргумент не таблица, верни пустую таблицу.</t>
<t>Используй цикл, <k>UnitMana</k>, <k>UnitManaMax</k>, <k>math.floor</k> и накопление в таблицу.</t>
<w>Ничего выводить не нужно.</w>
]=],
    initialCode = [=[
function BuildResourceMap(units)

end
]=],
    requireKeywords = {
        "BuildResourceMap",
        "function",
        "for",
        "UnitMana",
        "UnitManaMax",
        "math.floor",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        for i = 1, 4 do
            _G["test" .. i] = nil
        end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.BuildResourceMap) ~= "function" then
            return fail("BuildResourceMap не является глобальной функцией")
        end

        local okExists, exists = pcall(UnitExists, "target")
        if not okExists or not exists then
            return fail("Нет цели. Возьми в цель любого юнита и нажми проверку снова.")
        end

        local function livePercent(unit)
            if not UnitExists(unit) then
                return 0
            end
            local cur = UnitMana(unit) or 0
            local max = UnitManaMax(unit) or 0
            if max <= 0 then
                return 0
            end
            return math.floor(cur / max * 100)
        end

        local function fmtMap(t)
            local keys = {}
            for k in pairs(t) do
                table.insert(keys, tostring(k))
            end
            table.sort(keys)
            local p = {}
            for _, k in ipairs(keys) do
                table.insert(p, k .. "=" .. tostring(t[k]))
            end
            return "{" .. table.concat(p, ", ") .. "}"
        end

        local tests = {
            {input = {"player", "target", "ns_invalid"}},
            {input = {"player", "player"}},
            {input = {}},
            {input = "bad"},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(_G.BuildResourceMap, test.input)
            
            local expParts = {}
            if type(test.input) == "table" then
                for _, unit in ipairs(test.input) do
                    expParts[unit] = livePercent(unit)
                end
            end

            _G["test" .. i] = "Получено: " .. (type(result) == "table" and fmtMap(result) or tostring(result)) .. " | Ожидалось: " .. fmtMap(expParts)

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("Тест " .. i .. ": функция должна вернуть таблицу")
            end

            local expCount = 0
            for _ in pairs(expParts) do
                expCount = expCount + 1
            end

            local resCount = 0
            for _ in pairs(result) do
                resCount = resCount + 1
            end

            if resCount ~= expCount then
                return fail("Тест " .. i .. " не пройден")
            end

            for unit, exp in pairs(expParts) do
                local got = result[unit]
                -- got ~= got отлавливает NaN (-1.#IND), который возникает при делении 0/0
                if type(got) ~= "number" or got ~= got or math.abs(got - exp) > 5 then
                    return fail("Тест " .. i .. " не пройден")
                end
            end
        end

        return true
    end,
}

ns_llua['lua'][88] = {
    type = "commenttest",
    title = "Тест 83-5: функция GetTargetSummary",
    helpModules = {83, 65, 77, 7, 45},
    preloadVars = {
        {var = "GetTargetSummary", desc = "GetTargetSummary очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2"},
    instruction = [=[
<h>Тест 83-5: функция GetTargetSummary</h>
<t>Создай глобальную функцию <k>GetTargetSummary(unit)</k>.</t>
<t>Функция должна вернуть одну строку в формате:</t>
<s>"Имя: Тралл, Тип: моб, HP: 100%, Ресурс: 0%"</s>
<t>Тип: если юнит — игрок, выводи <s>"игрок"</s>, иначе — <s>"моб"</s>.</t>
<w>Возьми в цель игрока, а в фокус — моба (или наоборот).</w>
<w>Бонусная награда: если длина твоего кода составит 300 символов или меньше, ты получишь бонус!</w>
]=],
    initialCode = [=[
function GetTargetSummary(unit)
    
end
]=],
    requireKeywords = {
        "GetTargetSummary",
        "function",
        "UnitGUID",
        "UnitName",
        "UnitHealth",
        "UnitHealthMax",
        "UnitMana",
        "UnitManaMax",
        "0x0000",
        "return",
        "unit"
    },
    checkCode = function()
        _G.checkError = nil
        _G.test1 = nil
        _G.test2 = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetTargetSummary) ~= "function" then
            return fail("GetTargetSummary не является глобальной функцией")
        end

        local okTarget, targetExists = pcall(UnitExists, "target")
        local okFocus, focusExists = pcall(UnitExists, "focus")

        if not okTarget or not targetExists then
            return fail("Нет цели. Возьми кого-нибудь в цель.")
        end

        if not okFocus or not focusExists then
            return fail("Нет фокуса. Возьми кого-нибудь в фокус.")
        end

        local _, targetGuid = pcall(UnitGUID, "target")
        local _, focusGuid = pcall(UnitGUID, "focus")

        if type(targetGuid) ~= "string" or type(focusGuid) ~= "string" then
            return fail("Не удалось получить GUID для target или focus.")
        end

        local targetIsPlayer = string.sub(targetGuid, 1, 6) == "0x0000"
        local focusIsPlayer = string.sub(focusGuid, 1, 6) == "0x0000"

        if targetIsPlayer == focusIsPlayer then
            return fail("Один из юнитов (target или focus) должен быть игроком, другой — нет.")
        end

        local function livePercent(cur, max)
            if max <= 0 then
                return 0
            end
            return math.floor(cur / max * 100)
        end

        local function checkUnit(unit, testNum)
            local ok, result = pcall(_G.GetTargetSummary, unit)
            if not ok then
                return fail("Ошибка вызова GetTargetSummary('" .. unit .. "'): " .. tostring(result))
            end

            if type(result) ~= "string" then
                return fail("GetTargetSummary('" .. unit .. "') должна вернуть строку")
            end

            local name, typ, hp, res = result:match("^Имя: (.-), Тип: (.-), HP: (%d+)%%, Ресурс: (%d+)%%$")
            
            _G["test" .. testNum] = unit .. ": " .. result

            if not name then
                return fail("Строка для '" .. unit .. "' не похожа на 'Имя: X, Тип: Y, HP: N%, Ресурс: M%'")
            end

            local expectedName = UnitName(unit)
            if name ~= expectedName then
                return fail("Имя для '" .. unit .. "' не совпадает")
            end

            local _, guid = pcall(UnitGUID, unit)
            local isPlayer = string.sub(guid, 1, 6) == "0x0000"
            local expectedType = isPlayer and "игрок" or "моб"

            if typ ~= expectedType then
                return fail("Тип для '" .. unit .. "' должен быть '" .. expectedType .. "', получено '" .. typ .. "'")
            end

            local hpExp = livePercent(UnitHealth(unit) or 0, UnitHealthMax(unit) or 0)
            local resExp = livePercent(UnitMana(unit) or 0, UnitManaMax(unit) or 0)

            if math.abs(tonumber(hp) - hpExp) > 5 then
                return fail("Процент HP для '" .. unit .. "' не совпадает")
            end

            if math.abs(tonumber(res) - resExp) > 5 then
                return fail("Процент ресурса для '" .. unit .. "' не совпадает")
            end

            return true
        end

        local err1 = checkUnit("target", 1)
        if err1 ~= true then
            return err1
        end

        local err2 = checkUnit("focus", 2)
        if err2 ~= true then
            return err2
        end

        return true
    end,
}

ns_llua['lua'][89] = {
type = "info",
title = "Состояние юнита",
helpModules = {77, 83},
content = [=[
<h>Состояние юнита</h>
<t>Эти функции помогают проверить базовое состояние юнита: жив, мёртв, в бою, онлайн, AFK и так далее.</t>
<h>Жив или мёртв</h>
<code>
/run print(UnitIsDead("player"))
/run print(UnitIsGhost("player"))
</code>
<t>Если функция возвращает истинное значение, условие сработает. Если <k>nil</k> или <k>false</k> — не сработает.</t>
<h>Пример: мёртв или призрак</h>
<t>Отдельной функции «мёртв или призрак» в 3.3.5 нет, поэтому используем <k>or</k>:</t>
<code>
/run if UnitIsDead("player") or UnitIsGhost("player") then print("Мёртв или призрак") else print("Жив") end
</code>
<h>Бой</h>
<code>
/run print(UnitAffectingCombat("player"))
</code>
<t>Пример условия:</t>
<code>
/run if UnitAffectingCombat("player") then print("В бою") else print("Не в бою") end
</code>
<h>Подключение и статусы</h>
<code>
/run print(UnitIsConnected("player"))
/run print(UnitIsAFK("player"))
/run print(UnitIsDND("player"))
</code>
<c>UnitIsConnected</c> — юнит онлайн.
<c>UnitIsAFK</c> — режим AFK.
<c>UnitIsDND</c> — режим «не беспокоить».

<h>Таблица статусов</h>
<code>
/run local status = { dead = UnitIsDead("player"), ghost = UnitIsGhost("player"), combat = UnitAffectingCombat("player") }; print(status.dead, status.ghost, status.combat)
</code>
<t>Такие таблицы удобно использовать для панелей и отчётов.</t>
<h>Приведение к boolean</h>
<t>Так как WoW API может возвращать <k>1</k> или <k>nil</k>, удобно превращать результат в чистый <k>true</k> / <k>false</k>:</t>
<code>
/run local isDead = not not UnitIsDead("player"); print(isDead, type(isDead))
</code>
]=],
}

ns_llua['lua'][90] = {
    type = "commenttest",
    title = "Тест 89-1: функция GetUnitStatus",
    helpModules = {89, 45, 44, 19},
    preloadVars = {
        {var = "GetUnitStatus", desc = "GetUnitStatus очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2"},
    instruction = [=[
<h>Тест 89-1: функция GetUnitStatus</h>
<t>Создай глобальную функцию <k>GetUnitStatus(unit)</k>.</t>
<t>Функция должна вернуть хэш-таблицу с boolean-полями:</t>
<c>exists</c> — юнит существует.
<c>connected</c> — юнит онлайн.
<c>dead</c> — юнит мёртв.
<c>ghost</c> — юнит призрак.
<c>combat</c> — юнит в бою.
<t>Все значения должны быть чистыми boolean (true/false).</t>
<w>Возьми в цель любого юнита, а в фокус — другого.</w>
<w>Тест проверит обоих юнитов (target и focus) и сравнит их состояния.</w>
<w>Хотя бы одно поле должно различаться между target и focus, иначе тест попросит выбрать других юнитов.</w>
]=],
    initialCode = [=[
function GetUnitStatus(unit)
    
end
]=],
    requireKeywords = {
        "GetUnitStatus",
        "function",
        "UnitExists",
        "UnitIsConnected",
        "UnitIsDead",
        "UnitIsGhost",
        "UnitAffectingCombat",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.test1 = nil
        _G.test2 = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetUnitStatus) ~= "function" then
            return fail("GetUnitStatus не является глобальной функцией")
        end

        local okTarget, targetExists = pcall(UnitExists, "target")
        local okFocus, focusExists = pcall(UnitExists, "focus")

        if not okTarget or not targetExists then
            return fail("Нет цели. Возьми любого юнита в цель.")
        end
        if not okFocus or not focusExists then
            return fail("Нет фокуса. Возьми любого юнита в фокус.")
        end

        local function getExpectedStatus(unit)
            return {
                exists = not not UnitExists(unit),
                connected = not not UnitIsConnected(unit),
                dead = not not UnitIsDead(unit),
                ghost = not not UnitIsGhost(unit),
                combat = not not UnitAffectingCombat(unit),
            }
        end

        local fields = {"exists", "connected", "dead", "ghost", "combat"}

        local function checkUnit(unit, testNum)
            local ok, result = pcall(_G.GetUnitStatus, unit)
            
            if not ok then
                return fail("Ошибка вызова GetUnitStatus('" .. unit .. "'): " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("GetUnitStatus('" .. unit .. "') должна вернуть таблицу, получено " .. type(result))
            end

            local expected = getExpectedStatus(unit)
            local parts = {}

            for _, field in ipairs(fields) do
                if result[field] == nil then
                    return fail("В таблице для '" .. unit .. "' отсутствует поле '" .. field .. "'")
                end
                if type(result[field]) ~= "boolean" then
                    return fail("Поле '" .. field .. "' для '" .. unit .. "' должно быть boolean, получено " .. type(result[field]))
                end
                if result[field] ~= expected[field] then
                    return fail("Поле '" .. field .. "' для '" .. unit .. "': ожидалось " .. tostring(expected[field]) .. ", получено " .. tostring(result[field]))
                end
                table.insert(parts, field .. "=" .. tostring(result[field]))
            end

            _G["test" .. testNum] = unit .. ": {" .. table.concat(parts, ", ") .. "}"
            
            return true, result
        end

        local err1, resultTarget = checkUnit("target", 1)
        if err1 ~= true then
            return err1
        end

        local err2, resultFocus = checkUnit("focus", 2)
        if err2 ~= true then
            return err2
        end

        local differences = 0
        for _, field in ipairs(fields) do
            if resultTarget[field] ~= resultFocus[field] then
                differences = differences + 1
            end
        end

        if differences < 1 then
            return fail("Состояния target и focus идентичны. Выбери юнитов с разными состояниями.")
        end

        return true
    end,
}

ns_llua['lua'][91] = {
    type = "commenttest",
    title = "Тест 89-2: функция FilterSafeUnits",
    helpModules = {89, 45, 31, 29},
    preloadVars = {
        {var = "FilterSafeUnits", desc = "FilterSafeUnits очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4"},
    instruction = [=[
<h>Тест 89-2: функция FilterSafeUnits</h>
<t>Создай глобальную функцию <k>FilterSafeUnits(units)</k>.</t>
<t>Аргумент <k>units</k> — массив строк UnitID.</t>
<t>Функция должна вернуть новый массив, содержащий только тех юнитов, которые:</t>
<t>- существуют</t>
<t>- живы (не мёртвы и не призраки)</t>
<t>- не в бою</t>
<t>Порядок юнитов в результирующем массиве должен совпадать с исходным.</t>
<t>Если аргумент не таблица, верни пустой массив.</t>
<w>Во время проверки система подставит свои тестовые значения, искать юнитов не нужно.</w>
]=],
    initialCode = [=[
function FilterSafeUnits(units)
    
end
]=],
    requireKeywords = {
        "FilterSafeUnits",
        "function",
        "for",
        "UnitExists",
        "UnitIsDead",
        "UnitIsGhost",
        "UnitAffectingCombat",
        "return",
    },

    mockGlobals = {
        UnitExists = function(u)
            local mock = {
                safe1 = true, safe2 = true,
                dead = true, ghost = true, combat = true,
                missing = false,
            }
            return mock[u] == true
        end,
        UnitIsDead = function(u)
            local mock = {
                safe1 = false, safe2 = false,
                dead = true, ghost = false, combat = false,
                missing = false,
            }
            return mock[u] == true
        end,
        UnitIsGhost = function(u)
            local mock = {
                safe1 = false, safe2 = false,
                dead = false, ghost = true, combat = false,
                missing = false,
            }
            return mock[u] == true
        end,
        UnitAffectingCombat = function(u)
            local mock = {
                safe1 = false, safe2 = false,
                dead = false, ghost = false, combat = true,
                missing = false,
            }
            return mock[u] == true
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 4 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.FilterSafeUnits
        if type(fn) ~= "function" then
            return fail("FilterSafeUnits не является глобальной функцией")
        end

        local tests = {
            {input = {"safe1", "dead", "safe2"},      exp = {"safe1", "safe2"}},
            {input = {"combat", "safe1", "ghost"},    exp = {"safe1"}},
            {input = {"missing", "dead", "combat"},   exp = {}},
            {input = "bad",                           exp = {}},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.input)

            _G["test" .. i] = "Получено: {" .. table.concat(result or {}, ", ") .. "} | Ожидалось: {" .. table.concat(test.exp, ", ") .. "}"

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("Тест " .. i .. ": функция должна вернуть таблицу")
            end

            if #result ~= #test.exp then
                return fail("Тест " .. i .. " не пройден: не совпадает длина массива")
            end

            for j = 1, #result do
                if result[j] ~= test.exp[j] then
                    return fail("Тест " .. i .. " не пройден: элемент " .. j .. " не совпадает")
                end
            end
        end

        return true
    end,
}

ns_llua['lua'][92] = {
    type = "commenttest",
    title = "Тест 89-3: функция GetTargetReport",
    helpModules = {89, 45, 7, 17},
    preloadVars = {
        {var = "GetTargetReport", desc = "GetTargetReport очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 89-3: функция GetTargetReport</h>
<t>Создай глобальную функцию <k>GetTargetReport()</k>.</t>
<t>Перед проверкой возьми в цель любого юнита.</t>
<t>Функция должна вернуть одну строку в формате:</t>
<s>"Имя: Тралл, GUID: 0x0123456789AB, HP: 12500/15000, Состояние: жив"</s>
<t>Поля строки:</t>
<c>Имя</c> — через <k>UnitName("target")</k>.
<c>GUID</c> — полный GUID через <k>UnitGUID("target")</k>.
<c>HP</c> — текущее и максимальное здоровье через <k>UnitHealth("target")</k> и <k>UnitHealthMax("target")</k>.
<c>Состояние</c> — <s>"мёртв"</s>, <s>"призрак"</s> или <s>"жив"</s> (в таком порядке приоритета).
]=],
    initialCode = [=[
function GetTargetReport()
    
end
]=],
    requireKeywords = {
        "GetTargetReport",
        "function",
        "UnitName",
        "UnitGUID",
        "UnitHealth",
        "UnitHealthMax",
        "UnitIsDead",
        "UnitIsGhost",
        "string.format",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil
        
        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetTargetReport) ~= "function" then
            return fail("GetTargetReport не является глобальной функцией")
        end

        local okExists, exists = pcall(UnitExists, "target")
        if not okExists or not exists then
            return fail("Нет цели. Возьми любого юнита в цель и нажми проверку снова.")
        end

        local ok, result = pcall(_G.GetTargetReport)
        
        -- Сохраняем результат в глобальную переменную, чтобы он отобразился в отчёте
        if ok then
            _G.result = result
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end
        
        if not ok then
            return fail("Ошибка вызова GetTargetReport: " .. tostring(result))
        end
        if type(result) ~= "string" then
            return fail("GetTargetReport должна вернуть строку")
        end

        local name, guid, hpCur, hpMax, state = result:match(
            "^Имя: (.+), GUID: ([0-9A-FxX]+), HP: (%d+)/(%d+), Состояние: (.+)$"
        )

        if not name then
            return fail("Строка не похожа на 'Имя: X, GUID: Y, HP: A/B, Состояние: Z'")
        end

        local expectedName = UnitName("target") or ""
        if name ~= expectedName then
            return fail("Имя не совпадает: ожидалось '" .. expectedName .. "', получено '" .. name .. "'")
        end

        local expectedGuid = UnitGUID("target") or ""
        if guid ~= expectedGuid then
            return fail("GUID не совпадает: ожидалось '" .. expectedGuid .. "', получено '" .. guid .. "'")
        end

        local expHpCur = UnitHealth("target") or 0
        local expHpMax = UnitHealthMax("target") or 0

        if tonumber(hpCur) ~= expHpCur then
            return fail("Текущее HP не совпадает: ожидалось " .. expHpCur .. ", получено " .. hpCur)
        end
        if tonumber(hpMax) ~= expHpMax then
            return fail("Максимальное HP не совпадает: ожидалось " .. expHpMax .. ", получено " .. hpMax)
        end

        local expectedState
        if UnitIsDead("target") then
            expectedState = "мёртв"
        elseif UnitIsGhost("target") then
            expectedState = "призрак"
        else
            expectedState = "жив"
        end

        if state ~= expectedState then
            return fail("Состояние не совпадает: ожидалось '" .. expectedState .. "', получено '" .. state .. "'")
        end

        return true
    end,
}

ns_llua['lua'][93] = {
    type = "commenttest",
    title = "Тест 89-4: функция GetRaidStatusReport",
    helpModules = {89, 45, 44, 31, 7},
    preloadVars = {
        {var = "GetRaidStatusReport", desc = "GetRaidStatusReport очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 89-4: функция GetRaidStatusReport</h>
<t>Создай глобальную функцию <k>GetRaidStatusReport()</k>.</t>
<t>Функция должна собрать отчёт по всем участникам рейда и вернуть массив строк.</t>
<t>Формат каждой строки:</t>
<s>"Имя: Тралл, HP: 85%, Состояние: жив"</s>
<t>Состояние определяется по приоритету (сверху вниз):</t>
<c>"мёртв"</c> — юнит мёртв.
<c>"призрак"</c> — юнит призрак.
<c>"в бою"</c> — юнит жив и находится в бою.
<c>"жив"</c> — юнит просто жив.
<t>Процент здоровья — целое число, округлённое вниз.</t>
<t>Массив должен быть отсортирован по алфавиту имён (от А до Я).</t>
<t>Несуществующих юнитов пропускай.</t>
]=],
    initialCode = [=[
function GetRaidStatusReport()
    
end
]=],
    requireKeywords = {
        "GetRaidStatusReport",
        "function",
        "GetNumRaidMembers",
        "for",
        "UnitName",
        "UnitHealth",
        "UnitHealthMax",
        "UnitIsDead",
        "UnitIsGhost",
        "UnitAffectingCombat",
        "table.sort",
        "string.format",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil
        
        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetRaidStatusReport) ~= "function" then
            return fail("GetRaidStatusReport не является глобальной функцией")
        end

        local numRaid = GetNumRaidMembers()
        if numRaid < 3 then
            return fail("Нет рейда или мало игроков (" .. numRaid .. "/3). Собери рейд минимум из 3 человек и нажми проверку снова.")
        end

        local ok, result = pcall(_G.GetRaidStatusReport)
        
        if ok and type(result) == "table" then
            _G.result = result
        elseif ok then
            _G.result = "ОШИБКА: функция вернула " .. type(result)
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end
        
        if not ok then
            return fail("Ошибка вызова GetRaidStatusReport: " .. tostring(result))
        end
        if type(result) ~= "table" then
            return fail("GetRaidStatusReport должна вернуть массив (таблицу)")
        end

        local expected = {}
        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitExists(unit) then
                local name = UnitName(unit) or "Unknown"
                local hpCur = UnitHealth(unit) or 0
                local hpMax = UnitHealthMax(unit) or 0
                local hpPercent = 0
                if hpMax > 0 then
                    hpPercent = math.floor(hpCur / hpMax * 100)
                end
                
                local state
                if UnitIsDead(unit) then
                    state = "мёртв"
                elseif UnitIsGhost(unit) then
                    state = "призрак"
                elseif UnitAffectingCombat(unit) then
                    state = "в бою"
                else
                    state = "жив"
                end
                
                local line = string.format("Имя: %s, HP: %d%%, Состояние: %s", name, hpPercent, state)
                table.insert(expected, {name = name, line = line})
            end
        end

        table.sort(expected, function(a, b)
            return a.name < b.name
        end)

        if #result ~= #expected then
            return fail("Количество строк не совпадает: ожидалось " .. #expected .. ", получено " .. #result)
        end

        for i = 1, #expected do
            if result[i] ~= expected[i].line then
                return fail("Строка " .. i .. " не совпадает. Ожидалось: '" .. expected[i].line .. "', получено: '" .. tostring(result[i]) .. "'")
            end
        end

        return true
    end,
}

ns_llua['lua'][94] = {
    type = "commenttest",
    title = "Тест 89-5: функция GetGroupAlarm",
    helpModules = {89, 45, 31, 44, 52},
    preloadVars = {
        {var = "GetGroupAlarm", desc = "GetGroupAlarm очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
        {var = "test5", desc = "test5 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4", "test5"},
    instruction = [=[
<h>Тест 89-5: функция GetGroupAlarm</h>
<t>Создай глобальную функцию <k>GetGroupAlarm(units)</k>.</t>
<t>Аргумент <k>units</k> — массив строк UnitID (условный рейд).</t>
<t>Функция должна оценить состояние всей группы и вернуть одно слово-статус по приоритету (сверху вниз):</t>
<s>"empty"</s> — если массив пустой или все юниты в нём не существуют.
<s>"wipe"</s> — если все существующие юниты мертвы или призраки (ни одного живого).
<s>"danger"</s> — если есть хотя бы один живой юнит в бою.
<s>"loss"</s> — если есть хотя бы один мёртв или призрак, но есть и живые (не в бою).
<s>"ok"</s> — если все существующие юниты живы и не в бою.
<t>Если аргумент не таблица, вернуть <s>"empty"</s>.</t>
<w>Во время проверки система подставит свои тестовые значения, искать юнитов не нужно.</w>
]=],
    initialCode = [=[
function GetGroupAlarm(units)
    
end
]=],
    requireKeywords = {
        "GetGroupAlarm",
        "function",
        "for",
        "UnitExists",
        "UnitIsDead",
        "UnitIsGhost",
        "UnitAffectingCombat",
        "return",
    },

    mockGlobals = {
        UnitExists = function(u)
            local mock = {
                alive1=true, alive2=true, alive3=true,
                combat1=true, combat2=true,
                dead1=true, dead2=true,
                ghost1=true,
                missing=false,
            }
            return mock[u] == true
        end,
        UnitIsDead = function(u)
            local mock = {
                alive1=false, alive2=false, alive3=false,
                combat1=false, combat2=false,
                dead1=true, dead2=true,
                ghost1=false,
                missing=false,
            }
            return mock[u] == true
        end,
        UnitIsGhost = function(u)
            local mock = {
                alive1=false, alive2=false, alive3=false,
                combat1=false, combat2=false,
                dead1=false, dead2=false,
                ghost1=true,
                missing=false,
            }
            return mock[u] == true
        end,
        UnitAffectingCombat = function(u)
            local mock = {
                alive1=false, alive2=false, alive3=false,
                combat1=true, combat2=true,
                dead1=false, dead2=false,
                ghost1=false,
                missing=false,
            }
            return mock[u] == true
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 5 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.GetGroupAlarm
        if type(fn) ~= "function" then
            return fail("GetGroupAlarm не является глобальной функцией")
        end

        local tests = {
            {input = {"alive1", "alive2", "alive3"},         exp = "ok",     label = "Все живы и не в бою"},
            {input = {"combat1", "alive1", "alive2"},        exp = "danger", label = "Есть живой в бою"},
            {input = {"dead1", "alive1", "alive2"},          exp = "loss",   label = "Есть потери, но есть живые"},
            {input = {"dead1", "ghost1", "dead2"},           exp = "wipe",   label = "Все мертвы или призраки"},
            {input = {"missing", "missing"},                 exp = "empty",  label = "Все отсутствуют"},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.input)

            _G["test" .. i] = test.label .. " | Получено: '" .. tostring(result) .. "' | Ожидалось: '" .. test.exp .. "'"

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "string" then
                return fail("Тест " .. i .. ": функция должна вернуть строку, получено " .. type(result))
            end

            if result ~= test.exp then
                return fail("Тест " .. i .. " не пройден")
            end
        end

        return true
    end,
}

ns_llua['lua'][95] = {
type = "info",
title = "Отношения к юниту",
helpModules = {77, 89},
content = [=[
<h>Отношения к юниту</h>
<t>Эти функции помогают понять, можно ли атаковать юнита, дружелюбен ли он, игрок ли это, PvP ли он.</t>
<h>UnitCanAttack</h>
<t>Проверяет, можешь ли ты атаковать юнита.</t>
<code>
/run print(UnitCanAttack("player", "target"))
</code>
<h>UnitIsEnemy</h>
<code>
/run print(UnitIsEnemy("player", "target"))
</code>
<h>UnitIsFriend</h>
<code>
/run print(UnitIsFriend("player", "target"))
</code>
<h>UnitCanCooperate</h>
<t>Проверяет, можно ли взаимодействовать с юнитом, например лечить его.</t>
<code>
/run print(UnitCanCooperate("player", "target"))
</code>
<h>PvP и фракция</h>
<code>
/run print(UnitIsPVP("player"))
/run print(UnitFactionGroup("player"))
</code>
<h>Безопасный пример</h>
<code>
/run if UnitExists("target") and UnitCanAttack("player", "target") then print("Цель можно атаковать") else print("Атаковать нельзя или цели нет") end
</code>
<w>Важно:</w> если цели нет, функции проверки цели могут вернуть <k>nil</k>. Поэтому сначала проверяй <k>UnitExists</k>.
<h>Комбинированное условие</h>
<code>
/run if UnitExists("target") and UnitIsFriend("player", "target") then print("Дружественная цель") end
</code>
<h>Приведение к boolean</h>
<code>
/run local canAttack = not not UnitCanAttack("player", "target"); print(canAttack, type(canAttack))
</code>
]=],
}

ns_llua['lua'][96] = {
    type = "commenttest",
    title = "Тест 95-1: функция GetRelationStatus",
    helpModules = {95, 45, 44, 19},
    preloadVars = {
        {var = "GetRelationStatus", desc = "GetRelationStatus очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2"},
    instruction = [=[
<h>Тест 95-1: функция GetRelationStatus</h>
<t>Создай глобальную функцию <k>GetRelationStatus(unit)</k>.</t>
<t>Функция должна вернуть хэш-таблицу с boolean-полями:</t>
<c>canAttack</c> — игрок может атаковать юнита.
<c>isEnemy</c> — юнит враждебен.
<c>isFriend</c> — юнит дружественен.
<c>canCooperate</c> — с юнитом можно взаимодействовать.
<c>isPvp</c> — у юнита включён PvP-флаг.
<t>Все значения должны быть чистыми boolean (true/false).</t>
<w>Возьми в цель любого юнита, а в фокус — другого.</w>
<w>Тест проверит обоих юнитов (target и focus) и сравнит их состояния.</w>
<w>Хотя бы одно поле должно различаться между target и focus, иначе тест попросит выбрать других юнитов.</w>
]=],
    initialCode = [=[
function GetRelationStatus(unit)
    
end
]=],
    requireKeywords = {
        "GetRelationStatus",
        "function",
        "UnitCanAttack",
        "UnitIsEnemy",
        "UnitIsFriend",
        "UnitCanCooperate",
        "UnitIsPVP",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.test1 = nil
        _G.test2 = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetRelationStatus) ~= "function" then
            return fail("GetRelationStatus не является глобальной функцией")
        end

        local okTarget, targetExists = pcall(UnitExists, "target")
        local okFocus, focusExists = pcall(UnitExists, "focus")

        if not okTarget or not targetExists then
            return fail("Нет цели. Возьми любого юнита в цель.")
        end
        if not okFocus or not focusExists then
            return fail("Нет фокуса. Возьми любого юнита в фокус.")
        end

        local function getExpectedStatus(unit)
            return {
                canAttack = not not UnitCanAttack("player", unit),
                isEnemy = not not UnitIsEnemy("player", unit),
                isFriend = not not UnitIsFriend("player", unit),
                canCooperate = not not UnitCanCooperate("player", unit),
                isPvp = not not UnitIsPVP(unit),
            }
        end

        local fields = {"canAttack", "isEnemy", "isFriend", "canCooperate", "isPvp"}

        local function checkUnit(unit, testNum)
            local ok, result = pcall(_G.GetRelationStatus, unit)

            if not ok then
                return fail("Ошибка вызова GetRelationStatus('" .. unit .. "'): " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("GetRelationStatus('" .. unit .. "') должна вернуть таблицу, получено " .. type(result))
            end

            local expected = getExpectedStatus(unit)
            local parts = {}

            for _, field in ipairs(fields) do
                if result[field] == nil then
                    return fail("В таблице для '" .. unit .. "' отсутствует поле '" .. field .. "'")
                end
                if type(result[field]) ~= "boolean" then
                    return fail("Поле '" .. field .. "' для '" .. unit .. "' должно быть boolean, получено " .. type(result[field]))
                end
                if result[field] ~= expected[field] then
                    return fail("Поле '" .. field .. "' для '" .. unit .. "': ожидалось " .. tostring(expected[field]) .. ", получено " .. tostring(result[field]))
                end
                table.insert(parts, field .. "=" .. tostring(result[field]))
            end

            _G["test" .. testNum] = unit .. ": {" .. table.concat(parts, ", ") .. "}"

            return true, result
        end

        local err1, resultTarget = checkUnit("target", 1)
        if err1 ~= true then return err1 end

        local err2, resultFocus = checkUnit("focus", 2)
        if err2 ~= true then return err2 end

        local differences = 0
        for _, field in ipairs(fields) do
            if resultTarget[field] ~= resultFocus[field] then
                differences = differences + 1
            end
        end

        if differences < 1 then
            return fail("Состояния target и focus идентичны. Выбери юнитов с разными отношениями.")
        end

        return true
    end,
}

ns_llua['lua'][97] = {
    type = "commenttest",
    title = "Тест 95-2: функция GetTargetRelation",
    helpModules = {95, 45, 7, 17},
    preloadVars = {
        {var = "GetTargetRelation", desc = "GetTargetRelation очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 95-2: функция GetTargetRelation</h>
<t>Создай глобальную функцию <k>GetTargetRelation()</k>.</t>
<t>Перед проверкой возьми в цель любого юнита.</t>
<t>Функция должна вернуть одну строку в формате:</t>
<s>"Имя: Тралл, Фракция: Орда, Отношение: враг, Атака: да"</s>
<t>Поля строки:</t>
<c>Имя</c> — имя цели.
<c>Фракция</c> — <s>"Альянс"</s>, <s>"Орда"</s> или <s>"нейтрал"</s> (если фракции нет).
<c>Отношение</c> — <s>"враг"</s>, если юнит враждебен; <s>"друг"</s>, если дружественен; <s>"нейтрал"</s> в остальных случаях.
<c>Атака</c> — <s>"да"</s>, если игрок может атаковать цель, иначе <s>"нет"</s>.
]=],
    initialCode = [=[
function GetTargetRelation()
    
end
]=],
    requireKeywords = {
        "GetTargetRelation",
        "function",
        "UnitName",
        "UnitFactionGroup",
        "UnitIsEnemy",
        "UnitIsFriend",
        "UnitCanAttack",
        "string.format",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetTargetRelation) ~= "function" then
            return fail("GetTargetRelation не является глобальной функцией")
        end

        local okExists, exists = pcall(UnitExists, "target")
        if not okExists or not exists then
            return fail("Нет цели. Возьми любого юнита в цель и нажми проверку снова.")
        end

        local ok, result = pcall(_G.GetTargetRelation)

        if ok then
            _G.result = result
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова GetTargetRelation: " .. tostring(result))
        end
        if type(result) ~= "string" then
            return fail("GetTargetRelation должна вернуть строку")
        end

        local name, faction, relation, attack = result:match(
            "^Имя: (.+), Фракция: (.+), Отношение: (.+), Атака: (.+)$"
        )

        if not name then
            return fail("Строка не похожа на 'Имя: X, Фракция: Y, Отношение: Z, Атака: W'")
        end

        local expectedName = UnitName("target") or ""
        if name ~= expectedName then
            return fail("Имя не совпадает: ожидалось '" .. expectedName .. "', получено '" .. name .. "'")
        end

        local factionToken = UnitFactionGroup("target")
        local expectedFaction
        if factionToken == "Alliance" then
            expectedFaction = "Альянс"
        elseif factionToken == "Horde" then
            expectedFaction = "Орда"
        else
            expectedFaction = "нейтрал"
        end
        if faction ~= expectedFaction then
            return fail("Фракция не совпадает: ожидалось '" .. expectedFaction .. "', получено '" .. faction .. "'")
        end

        local expectedRelation
        if UnitIsEnemy("player", "target") then
            expectedRelation = "враг"
        elseif UnitIsFriend("player", "target") then
            expectedRelation = "друг"
        else
            expectedRelation = "нейтрал"
        end
        if relation ~= expectedRelation then
            return fail("Отношение не совпадает: ожидалось '" .. expectedRelation .. "', получено '" .. relation .. "'")
        end

        local expectedAttack = UnitCanAttack("player", "target") and "да" or "нет"
        if attack ~= expectedAttack then
            return fail("Атака не совпадает: ожидалось '" .. expectedAttack .. "', получено '" .. attack .. "'")
        end

        return true
    end,
}

ns_llua['lua'][98] = {
    type = "commenttest",
    title = "Тест 95-3: функция FilterAttackableUnits",
    helpModules = {95, 45, 31, 29},
    preloadVars = {
        {var = "FilterAttackableUnits", desc = "FilterAttackableUnits очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4"},
    instruction = [=[
<h>Тест 95-3: функция FilterAttackableUnits</h>
<t>Создай глобальную функцию <k>FilterAttackableUnits(units)</k>.</t>
<t>Аргумент <k>units</k> — массив строк UnitID.</t>
<t>Функция должна вернуть новый массив, содержащий только тех юнитов, которых игрок может атаковать.</t>
<t>Порядок юнитов в результирующем массиве должен совпадать с исходным.</t>
<t>Если аргумент не таблица, верни пустой массив.</t>
<w>Во время проверки система подставит свои тестовые значения, искать юнитов не нужно.</w>
]=],
    initialCode = [=[
function FilterAttackableUnits(units)
    
end
]=],
    requireKeywords = {
        "FilterAttackableUnits",
        "function",
        "for",
        "UnitCanAttack",
        "return",
    },

    mockGlobals = {
        UnitCanAttack = function(attacker, u)
            local mock = {
                enemy1 = true, enemy2 = true,
                friend1 = false, friend2 = false,
                neutral = false,
            }
            return mock[u] == true
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 4 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.FilterAttackableUnits
        if type(fn) ~= "function" then
            return fail("FilterAttackableUnits не является глобальной функцией")
        end

        local tests = {
            {input = {"enemy1", "friend1", "enemy2"},   exp = {"enemy1", "enemy2"}},
            {input = {"friend1", "enemy1", "neutral"},  exp = {"enemy1"}},
            {input = {"friend1", "friend2", "neutral"}, exp = {}},
            {input = "bad",                             exp = {}},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.input)

            _G["test" .. i] = "Получено: {" .. table.concat(result or {}, ", ") .. "} | Ожидалось: {" .. table.concat(test.exp, ", ") .. "}"

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("Тест " .. i .. ": функция должна вернуть таблицу")
            end

            if #result ~= #test.exp then
                return fail("Тест " .. i .. " не пройден: не совпадает длина массива")
            end

            for j = 1, #result do
                if result[j] ~= test.exp[j] then
                    return fail("Тест " .. i .. " не пройден: элемент " .. j .. " не совпадает")
                end
            end
        end

        return true
    end,
}

ns_llua['lua'][99] = {
    type = "commenttest",
    title = "Тест 95-4: функция CompareTargets",
    helpModules = {95, 45, 17, 7},
    preloadVars = {
        {var = "CompareTargets", desc = "CompareTargets очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 95-4: функция CompareTargets</h>
<t>Создай глобальную функцию <k>CompareTargets()</k>.</t>
<t>Перед проверкой возьми в цель любого юнита, а в фокус — другого.</t>
<t>Функция должна вернуть одну строку в формате:</t>
<s>"Цель: враг, Фокус: друг, Атаковать: цель"</s>
<t>Поля строки:</t>
<c>Цель</c> — отношение к цели (<s>"враг"</s>, <s>"друг"</s> или <s>"нейтрал"</s>).
<c>Фокус</c> — отношение к фокусу (<s>"враг"</s>, <s>"друг"</s> или <s>"нейтрал"</s>).
<c>Атаковать</c> — кого из двух юнитов игрок может атаковать. Если обоих — <s>"оба"</s>. Если никого — <s>"никто"</s>. Если только одного — <s>"цель"</s> или <s>"фокус"</s>.
]=],
    initialCode = [=[
function CompareTargets()
    
end
]=],
    requireKeywords = {
        "CompareTargets",
        "function",
        "UnitIsEnemy",
        "UnitIsFriend",
        "UnitCanAttack",
        "string.format",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.CompareTargets) ~= "function" then
            return fail("CompareTargets не является глобальной функцией")
        end

        local okTarget, targetExists = pcall(UnitExists, "target")
        local okFocus, focusExists = pcall(UnitExists, "focus")

        if not okTarget or not targetExists then
            return fail("Нет цели. Возьми любого юнита в цель.")
        end
        if not okFocus or not focusExists then
            return fail("Нет фокуса. Возьми любого юнита в фокус.")
        end

        local ok, result = pcall(_G.CompareTargets)

        if ok then
            _G.result = result
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова CompareTargets: " .. tostring(result))
        end
        if type(result) ~= "string" then
            return fail("CompareTargets должна вернуть строку")
        end

        local targetRel, focusRel, attackTarget = result:match(
            "^Цель: (.+), Фокус: (.+), Атаковать: (.+)$"
        )

        if not targetRel then
            return fail("Строка не похожа на 'Цель: X, Фокус: Y, Атаковать: Z'")
        end

        local function getRelation(unit)
            if UnitIsEnemy("player", unit) then
                return "враг"
            elseif UnitIsFriend("player", unit) then
                return "друг"
            else
                return "нейтрал"
            end
        end

        local expectedTargetRel = getRelation("target")
        local expectedFocusRel = getRelation("focus")

        if targetRel ~= expectedTargetRel then
            return fail("Отношение к цели не совпадает: ожидалось '" .. expectedTargetRel .. "', получено '" .. targetRel .. "'")
        end
        if focusRel ~= expectedFocusRel then
            return fail("Отношение к фокусу не совпадает: ожидалось '" .. expectedFocusRel .. "', получено '" .. focusRel .. "'")
        end

        local canAttackTarget = not not UnitCanAttack("player", "target")
        local canAttackFocus = not not UnitCanAttack("player", "focus")

        local expectedAttack
        if canAttackTarget and canAttackFocus then
            expectedAttack = "оба"
        elseif canAttackTarget then
            expectedAttack = "цель"
        elseif canAttackFocus then
            expectedAttack = "фокус"
        else
            expectedAttack = "никто"
        end

        if attackTarget ~= expectedAttack then
            return fail("Атаковать не совпадает: ожидалось '" .. expectedAttack .. "', получено '" .. attackTarget .. "'")
        end

        return true
    end,
}

ns_llua['lua'][100] = {
    type = "commenttest",
    title = "Тест 95-5: функция GetGroupThreat",
    helpModules = {95, 45, 31, 44, 52},
    preloadVars = {
        {var = "GetGroupThreat", desc = "GetGroupThreat очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
        {var = "test5", desc = "test5 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4", "test5"},
    instruction = [=[
<h>Тест 95-5: функция GetGroupThreat</h>
<t>Создай глобальную функцию <k>GetGroupThreat(units)</k>.</t>
<t>Аргумент <k>units</k> — массив строк UnitID (условная группа).</t>
<t>Функция должна оценить группу по отношению к игроку и вернуть одно слово-статус по приоритету (сверху вниз):</t>
<s>"empty"</s> — если массив пустой или аргумент не таблица.
<s>"hostile"</s> — если есть хотя бы один враг, которого можно атаковать.
<s>"friendly"</s> — если все существующие юниты — друзья.
<s>"mixed"</s> — если есть и друзья, и нейтралы (но нет атакующихся врагов).
<s>"neutral"</s> — если все существующие юниты нейтральны.
<w>Во время проверки система подставит свои тестовые значения, искать юнитов не нужно.</w>
]=],
    initialCode = [=[
function GetGroupThreat(units)
    
end
]=],
    requireKeywords = {
        "GetGroupThreat",
        "function",
        "for",
        "UnitCanAttack",
        "UnitIsEnemy",
        "UnitIsFriend",
        "return",
    },

    mockGlobals = {
        UnitCanAttack = function(attacker, u)
            local mock = {
                enemy1=true, enemy2=true,
                friend1=false, friend2=false,
                neutral1=false, neutral2=false,
            }
            return mock[u] == true
        end,
        UnitIsEnemy = function(attacker, u)
            local mock = {
                enemy1=true, enemy2=true,
                friend1=false, friend2=false,
                neutral1=false, neutral2=false,
            }
            return mock[u] == true
        end,
        UnitIsFriend = function(attacker, u)
            local mock = {
                enemy1=false, enemy2=false,
                friend1=true, friend2=true,
                neutral1=false, neutral2=false,
            }
            return mock[u] == true
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 5 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.GetGroupThreat
        if type(fn) ~= "function" then
            return fail("GetGroupThreat не является глобальной функцией")
        end

        local tests = {
            {input = {"enemy1", "friend1", "neutral1"}, exp = "hostile",  label = "Есть атакующийся враг"},
            {input = {"friend1", "friend2"},            exp = "friendly",  label = "Все друзья"},
            {input = {"friend1", "neutral1"},           exp = "mixed",     label = "Друзья и нейтралы"},
            {input = {"neutral1", "neutral2"},          exp = "neutral",   label = "Все нейтралы"},
            {input = "bad",                             exp = "empty",      label = "Не таблица"},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.input)

            _G["test" .. i] = test.label .. " | Получено: '" .. tostring(result) .. "' | Ожидалось: '" .. test.exp .. "'"

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "string" then
                return fail("Тест " .. i .. ": функция должна вернуть строку, получено " .. type(result))
            end

            if result ~= test.exp then
                return fail("Тест " .. i .. " не пройден")
            end
        end

        return true
    end,
}

ns_llua['lua'][101] = {
type = "info",
title = "Описание юнита",
helpModules = {77, 83, 95},
content = [=[
<h>Описание юнита</h>
<t>Эти функции возвращают базовое описание юнита: уровень, расу, класс, пол, тип существа.</t>
<h>UnitLevel</h>
<code>
/run print(UnitLevel("player"))
/run print(UnitLevel("target"))
</code>
<w>Особенность:</w> уровень <k>-1</k> часто означает босса.
<h>UnitRace</h>
<code>
/run local race, raceToken = UnitRace("player"); print(race, raceToken)
</code>
<t>Первое значение — локализованное название расы.</t>
<t>Второе значение — технический токен, например <s>HUMAN</s> или <s>ORC</s>.</t>
<h>UnitClass</h>
<code>
/run local className, classToken = UnitClass("player"); print(className, classToken)
</code>
<t>Для логики лучше использовать токен:</t>
<code>
/run local _, token = UnitClass("player"); if token == "MAGE" then print("Маг") end
</code>
<h>UnitSex</h>
<code>
/run print(UnitSex("player"))
</code>
<h>UnitClassification</h>
<t>Возвращает тип сложности существа.</t>
<code>
/run print(UnitClassification("target"))
</code>
<t>Возможные значения:</t>
<c>normal</c>
<c>elite</c>
<c>rare</c>
<c>rareelite</c>
<c>worldboss</c>
<h>UnitCreatureType и UnitCreatureFamily</h>
<code>
/run print(UnitCreatureType("target"))
/run print(UnitCreatureFamily("target"))
</code>
<h>Мини-досье</h>
<code>
/run local name = UnitName("target") or "Нет цели"; local level = UnitLevel("target") or 0; local class = UnitClass("target") or "Неизвестно"; print(string.format("%s, уровень %s, класс %s", name, level, class))
</code>
]=],
}

ns_llua['lua'][102] = {
    type = "commenttest",
    title = "Тест 101-1: функция GetTargetDescription",
    helpModules = {101, 45, 44, 7},
    preloadVars = {
        {var = "GetTargetDescription", desc = "GetTargetDescription очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 101-1: функция GetTargetDescription</h>
<t>Создай глобальную функцию <k>GetTargetDescription()</k>.</t>
<t>Перед проверкой возьми в цель любого юнита.</t>
<t>Функция должна вернуть таблицу с полями:</t>
<c>name</c> — имя цели.
<c>level</c> — уровень цели (число).
<c>classToken</c> — токен класса цели (строка).
<c>raceToken</c> — токен расы цели (строка).
<t>Если поле получить нельзя, используй <k>nil</k>.</t>
<w>Тест проверит, что данные соответствуют реальной цели.</w>
]=],
    initialCode = [=[
function GetTargetDescription()
    
end
]=],
    requireKeywords = {
        "GetTargetDescription",
        "function",
        "UnitName",
        "UnitLevel",
        "UnitClass",
        "UnitRace",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetTargetDescription) ~= "function" then
            return fail("GetTargetDescription не является глобальной функцией")
        end

        local okExists, exists = pcall(UnitExists, "target")
        if not okExists or not exists then
            return fail("Нет цели. Возьми любого юнита в цель и нажми проверку снова.")
        end

        local ok, result = pcall(_G.GetTargetDescription)

        if ok and type(result) == "table" then
            _G.result = result
        elseif ok then
            _G.result = "ОШИБКА: функция вернула " .. type(result)
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова GetTargetDescription: " .. tostring(result))
        end
        if type(result) ~= "table" then
            return fail("GetTargetDescription должна вернуть таблицу")
        end

        local expectedName = UnitName("target")
        if result.name ~= expectedName then
            return fail("Имя не совпадает: ожидалось '" .. tostring(expectedName) .. "', получено '" .. tostring(result.name) .. "'")
        end

        local expectedLevel = UnitLevel("target")
        if result.level ~= expectedLevel then
            return fail("Уровень не совпадает: ожидалось " .. tostring(expectedLevel) .. ", получено " .. tostring(result.level))
        end

        local _, expectedClassToken = UnitClass("target")
        if result.classToken ~= expectedClassToken then
            return fail("Токен класса не совпадает: ожидалось '" .. tostring(expectedClassToken) .. "', получено '" .. tostring(result.classToken) .. "'")
        end

        local _, expectedRaceToken = UnitRace("target")
        if result.raceToken ~= expectedRaceToken then
            return fail("Токен расы не совпадает: ожидалось '" .. tostring(expectedRaceToken) .. "', получено '" .. tostring(result.raceToken) .. "'")
        end

        return true
    end,
}

ns_llua['lua'][103] = {
    type = "commenttest",
    title = "Тест 101-2: функция FilterByClass",
    helpModules = {101, 45, 31, 29},
    preloadVars = {
        {var = "FilterByClass", desc = "FilterByClass очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4"},
    instruction = [=[
<h>Тест 101-2: функция FilterByClass</h>
<t>Создай глобальную функцию <k>FilterByClass(units, classToken)</k>.</t>
<t>Аргумент <k>units</k> — массив строк UnitID.</t>
<t>Аргумент <k>classToken</k> — токен класса (например, <s>"MAGE"</s>, <s>"WARRIOR"</s>).</t>
<t>Функция должна вернуть новый массив, содержащий только тех юнитов, у которых токен класса совпадает с <k>classToken</k>.</t>
<t>Порядок юнитов в результирующем массиве должен совпадать с исходным.</t>
<t>Если аргумент не таблица или <k>classToken</k> не строка, верни пустой массив.</t>
<w>Во время проверки система подставит свои тестовые значения, искать юнитов не нужно.</w>
]=],
    initialCode = [=[
function FilterByClass(units, classToken)
    
end
]=],
    requireKeywords = {
        "FilterByClass",
        "function",
        "for",
        "UnitClass",
        "return",
    },

    mockGlobals = {
        UnitClass = function(u)
            local mock = {
                mage1 = {"Маг", "MAGE"},
                mage2 = {"Маг", "MAGE"},
                warrior1 = {"Воин", "WARRIOR"},
                warrior2 = {"Воин", "WARRIOR"},
                priest1 = {"Жрец", "PRIEST"},
                missing = {nil, nil},
            }
            local data = mock[u] or mock.missing
            return data[1], data[2]
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 4 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.FilterByClass
        if type(fn) ~= "function" then
            return fail("FilterByClass не является глобальной функцией")
        end

        local tests = {
            {units = {"mage1", "warrior1", "mage2"}, token = "MAGE", exp = {"mage1", "mage2"}},
            {units = {"warrior1", "priest1", "warrior2"}, token = "WARRIOR", exp = {"warrior1", "warrior2"}},
            {units = {"priest1", "mage1"}, token = "ROGUE", exp = {}},
            {units = "bad", token = "MAGE", exp = {}},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.units, test.token)

            _G["test" .. i] = "Получено: {" .. table.concat(result or {}, ", ") .. "} | Ожидалось: {" .. table.concat(test.exp, ", ") .. "}"

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("Тест " .. i .. ": функция должна вернуть таблицу")
            end

            if #result ~= #test.exp then
                return fail("Тест " .. i .. " не пройден: не совпадает длина массива")
            end

            for j = 1, #result do
                if result[j] ~= test.exp[j] then
                    return fail("Тест " .. i .. " не пройден: элемент " .. j .. " не совпадает")
                end
            end
        end

        return true
    end,
}

ns_llua['lua'][104] = {
    type = "commenttest",
    title = "Тест 101-3: функция CompareLevels",
    helpModules = {101, 45, 17},
    preloadVars = {
        {var = "CompareLevels", desc = "CompareLevels очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 101-3: функция CompareLevels</h>
<t>Создай глобальную функцию <k>CompareLevels()</k>.</t>
<t>Перед проверкой возьми в цель любого юнита, а в фокус — другого.</t>
<t>Функция должна вернуть одну строку в формате:</t>
<s>"Цель: 80, Фокус: 75, Разница: 5"</s>
<t>Поля строки:</t>
<c>Цель</c> — уровень цели (число).
<c>Фокус</c> — уровень фокуса (число).
<c>Разница</c> — абсолютная разница между уровнями (всегда положительное число или 0).
]=],
    initialCode = [=[
function CompareLevels()
    
end
]=],
    requireKeywords = {
        "CompareLevels",
        "function",
        "UnitLevel",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.CompareLevels) ~= "function" then
            return fail("CompareLevels не является глобальной функцией")
        end

        local okTarget, targetExists = pcall(UnitExists, "target")
        local okFocus, focusExists = pcall(UnitExists, "focus")

        if not okTarget or not targetExists then
            return fail("Нет цели. Возьми любого юнита в цель.")
        end
        if not okFocus or not focusExists then
            return fail("Нет фокуса. Возьми любого юнита в фокус.")
        end

        local ok, result = pcall(_G.CompareLevels)

        if ok then
            _G.result = result
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова CompareLevels: " .. tostring(result))
        end
        if type(result) ~= "string" then
            return fail("CompareLevels должна вернуть строку")
        end

        local targetLevel, focusLevel, diff = result:match(
            "^Цель: (%-?%d+), Фокус: (%-?%d+), Разница: (%d+)$"
        )

        if not targetLevel then
            return fail("Строка не похожа на 'Цель: X, Фокус: Y, Разница: Z'")
        end

        local expectedTargetLevel = UnitLevel("target") or 0
        local expectedFocusLevel = UnitLevel("focus") or 0
        local expectedDiff = math.abs(expectedTargetLevel - expectedFocusLevel)

        if tonumber(targetLevel) ~= expectedTargetLevel then
            return fail("Уровень цели не совпадает: ожидалось " .. expectedTargetLevel .. ", получено " .. targetLevel)
        end
        if tonumber(focusLevel) ~= expectedFocusLevel then
            return fail("Уровень фокуса не совпадает: ожидалось " .. expectedFocusLevel .. ", получено " .. focusLevel)
        end
        if tonumber(diff) ~= expectedDiff then
            return fail("Разница не совпадает: ожидалось " .. expectedDiff .. ", получено " .. diff)
        end

        return true
    end,
}

ns_llua['lua'][105] = {
    type = "commenttest",
    title = "Тест 101-4: функция FindBosses",
    helpModules = {101, 45, 31, 29},
    preloadVars = {
        {var = "FindBosses", desc = "FindBosses очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4"},
    instruction = [=[
<h>Тест 101-4: функция FindBosses</h>
<t>Создай глобальную функцию <k>FindBosses(units)</k>.</t>
<t>Аргумент <k>units</k> — массив строк UnitID.</t>
<t>Функция должна вернуть новый массив, содержащий только тех юнитов, у которых уровень равен <n>-1</n> (боссы).</t>
<t>Порядок юнитов в результирующем массиве должен совпадать с исходным.</t>
<t>Если аргумент не таблица, верни пустой массив.</t>
<w>Во время проверки система подставит свои тестовые значения, искать юнитов не нужно.</w>
]=],
    initialCode = [=[
function FindBosses(units)
    
end
]=],
    requireKeywords = {
        "FindBosses",
        "function",
        "for",
        "UnitLevel",
        "return",
    },

    mockGlobals = {
        UnitLevel = function(u)
            local mock = {
                boss1 = -1,
                boss2 = -1,
                mob1 = 80,
                mob2 = 75,
                elite = 82,
                missing = nil,
            }
            return mock[u]
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 4 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.FindBosses
        if type(fn) ~= "function" then
            return fail("FindBosses не является глобальной функцией")
        end

        local tests = {
            {input = {"boss1", "mob1", "boss2"}, exp = {"boss1", "boss2"}},
            {input = {"mob1", "elite", "mob2"}, exp = {}},
            {input = {"boss1", "boss2"}, exp = {"boss1", "boss2"}},
            {input = "bad", exp = {}},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.input)

            _G["test" .. i] = "Получено: {" .. table.concat(result or {}, ", ") .. "} | Ожидалось: {" .. table.concat(test.exp, ", ") .. "}"

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("Тест " .. i .. ": функция должна вернуть таблицу")
            end

            if #result ~= #test.exp then
                return fail("Тест " .. i .. " не пройден: не совпадает длина массива")
            end

            for j = 1, #result do
                if result[j] ~= test.exp[j] then
                    return fail("Тест " .. i .. " не пройден: элемент " .. j .. " не совпадает")
                end
            end
        end

        return true
    end,
}

ns_llua['lua'][106] = {
    type = "commenttest",
    title = "Тест 101-5: функция GetRaidClassReport",
    helpModules = {101, 45, 44, 31, 7},
    preloadVars = {
        {var = "GetRaidClassReport", desc = "GetRaidClassReport очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 101-5: функция GetRaidClassReport</h>
<t>Создай глобальную функцию <k>GetRaidClassReport()</k>.</t>
<t>Функция должна собрать отчёт по всем участникам рейда и вернуть массив строк.</t>
<t>Формат каждой строки:</t>
<s>"Имя: Тралл, Уровень: 80, Класс: WARRIOR"</s>
<t>Массив должен быть отсортирован по алфавиту имён (от А до Я).</t>
<t>Несуществующих юнитов пропускай.</t>
<w>Перед проверкой собери рейд минимум из 3 человек.</w>
]=],
    initialCode = [=[
function GetRaidClassReport()
    
end
]=],
    requireKeywords = {
        "GetRaidClassReport",
        "function",
        "GetNumRaidMembers",
        "for",
        "UnitName",
        "UnitLevel",
        "UnitClass",
        "table.sort",
        "string.format",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetRaidClassReport) ~= "function" then
            return fail("GetRaidClassReport не является глобальной функцией")
        end

        local numRaid = GetNumRaidMembers()
        if numRaid < 3 then
            return fail("Нет рейда или мало игроков (" .. numRaid .. "/3). Собери рейд минимум из 3 человек и нажми проверку снова.")
        end

        local ok, result = pcall(_G.GetRaidClassReport)

        if ok and type(result) == "table" then
            _G.result = result
        elseif ok then
            _G.result = "ОШИБКА: функция вернула " .. type(result)
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова GetRaidClassReport: " .. tostring(result))
        end
        if type(result) ~= "table" then
            return fail("GetRaidClassReport должна вернуть массив (таблицу)")
        end

        local expected = {}
        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitExists(unit) then
                local name = UnitName(unit) or "Unknown"
                local level = UnitLevel(unit) or 0
                local _, classToken = UnitClass(unit)
                classToken = classToken or "UNKNOWN"

                local line = string.format("Имя: %s, Уровень: %d, Класс: %s", name, level, classToken)
                table.insert(expected, {name = name, line = line})
            end
        end

        table.sort(expected, function(a, b)
            return a.name < b.name
        end)

        if #result ~= #expected then
            return fail("Количество строк не совпадает: ожидалось " .. #expected .. ", получено " .. #result)
        end

        for i = 1, #expected do
            if result[i] ~= expected[i].line then
                return fail("Строка " .. i .. " не совпадает. Ожидалось: '" .. expected[i].line .. "', получено: '" .. tostring(result[i]) .. "'")
            end
        end

        return true
    end,
}

ns_llua['lua'][107] = {
type = "info",
title = "Баффы и дебаффы как данные",
helpModules = {101, 31, 33},
content = [=[
<h>Баффы и дебаффы как данные</h>
<t>Баффы и дебаффы в WoW API обычно перебираются по индексу: 1, 2, 3 и так далее.</t>
<h>UnitBuff</h>
<code>
/run local name = UnitBuff("player", 1); print(name)
</code>
<t>Если баффа с таким индексом нет, функция вернёт <k>nil</k>.</t>
<h>UnitDebuff</h>
<code>
/run local name = UnitDebuff("player", 1); print(name)
</code>
<h>UnitAura</h>
<t>Более универсальная функция. Она может искать и баффы, и дебаффы.</t>
<code>
/run local name = UnitAura("player", 1, "HELPFUL"); print(name)
</code>
<c>"HELPFUL"</c> — баффы.
<c>"HARMFUL"</c> — дебаффы.
<h>Несколько возвращаемых значений</h>
<t>Функции аур возвращают много данных: имя, иконку, количество стаков, тип, длительность и время окончания.</t>
<code>
/run local name, _, _, count = UnitBuff("player", 1); print(name, count)
</code>
<h>Подсчёт баффов</h>
<code>
/run local count = 0; local i = 1; while UnitBuff("player", i) do count = count + 1; i = i + 1 end; print("Баффов:", count)
</code>
<h>Остаток времени</h>
<code>
/run local name, _, _, _, _, duration, expiration = UnitBuff("player", 1); if name and expiration and expiration > 0 then print(name, math.floor(expiration - GetTime())) end
</code>
<t>Если <k>duration</k> и <k>expirationTime</k> равны нулю, таймер у ауры может отсутствовать.</t>
<h>Поиск баффа по имени</h>
<code>
/run local found = false; for i = 1, 40 do local name = UnitBuff("player", i); if not name then break end; if string.find(name, "Бафф") then found = true end end; print(found)
</code>
<w>Важно:</w> точное имя баффа зависит от языка клиента. Поэтому в реальных аддонах часто используют spellID, если он доступен.
]=],
}

ns_llua['lua'][108] = {
    type = "commenttest",
    title = "Тест 107-1: функция CountAuras",
    helpModules = {107, 45, 44},
    preloadVars = {
        {var = "CountAuras", desc = "CountAuras очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 107-1: функция CountAuras</h>
<t>Создай глобальную функцию <k>CountAuras(unit)</k>.</t>
<t>Функция должна посчитать количество баффов и дебаффов на юните и вернуть таблицу с двумя полями:</t>
<c>buffs</c> — количество баффов.
<c>debuffs</c> — количество дебаффов.
<t>Перебирай индексы от 1, пока функция не вернёт <k>nil</k>.</t>
<t>Если юнита не существует, верни <s>{buffs = 0, debuffs = 0}</s>.</t>
<w>Перед проверкой возьми в цель любого юнита.</w>
]=],
    initialCode = [=[
function CountAuras(unit)
    
end
]=],
    requireKeywords = {
        "CountAuras",
        "function",
        "UnitBuff",
        "UnitDebuff",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.CountAuras) ~= "function" then
            return fail("CountAuras не является глобальной функцией")
        end

        local okExists, exists = pcall(UnitExists, "target")
        if not okExists or not exists then
            return fail("Нет цели. Возьми любого юнита в цель и нажми проверку снова.")
        end

        local ok, result = pcall(_G.CountAuras, "target")

        if ok and type(result) == "table" then
            _G.result = result
        elseif ok then
            _G.result = "ОШИБКА: функция вернула " .. type(result)
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова CountAuras: " .. tostring(result))
        end
        if type(result) ~= "table" then
            return fail("CountAuras должна вернуть таблицу")
        end

        local expectedBuffs = 0
        local expectedDebuffs = 0
        local i = 1
        while UnitBuff("target", i) do
            expectedBuffs = expectedBuffs + 1
            i = i + 1
        end
        i = 1
        while UnitDebuff("target", i) do
            expectedDebuffs = expectedDebuffs + 1
            i = i + 1
        end

        if result.buffs ~= expectedBuffs then
            return fail("Баффов ожидалось " .. expectedBuffs .. ", получено " .. tostring(result.buffs))
        end
        if result.debuffs ~= expectedDebuffs then
            return fail("Дебаффов ожидалось " .. expectedDebuffs .. ", получено " .. tostring(result.debuffs))
        end

        return true
    end,
}

ns_llua['lua'][109] = {
    type = "commenttest",
    title = "Тест 107-2: функция GetExpiringBuffs",
    helpModules = {107, 45, 31, 29},
    preloadVars = {
        {var = "GetExpiringBuffs", desc = "GetExpiringBuffs очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4"},
    instruction = [=[
<h>Тест 107-2: функция GetExpiringBuffs</h>
<t>Создай глобальную функцию <k>GetExpiringBuffs(unit, threshold)</k>.</t>
<t>Аргумент <k>unit</k> — UnitID, <k>threshold</k> — порог в секундах.</t>
<t>Функция должна вернуть массив имён баффов, у которых осталось меньше <k>threshold</k> секунд.</t>
<t>Оставшееся время считается как <k>expirationTime - GetTime()</k>.</t>
<t>Если у баффа нет таймера (<k>expirationTime</k> равно 0), он не попадает в результат.</t>
<t>Порядок имён в результирующем массиве должен совпадать с порядком баффов на юните.</t>
<t>Если <k>threshold</k> не число или <= 0, верни пустой массив.</t>
<w>Во время проверки система подставит свои тестовые значения, искать юнитов не нужно.</w>
]=],
    initialCode = [=[
function GetExpiringBuffs(unit, threshold)
    
end
]=],
    requireKeywords = {
        "GetExpiringBuffs",
        "function",
        "UnitBuff",
        "GetTime",
        "return",
    },

    mockGlobals = {
        GetTime = function() return 1000 end,
        UnitBuff = function(u, i)
            local mock = {
                player = {
                    {name = "Щит", duration = 30, expiration = 1025},
                    {name = "Ярость", duration = 10, expiration = 1005},
                    {name = "Благословение", duration = 60, expiration = 0},
                    {name = "Ускорение", duration = 8, expiration = 1003},
                },
                target = {
                    {name = "Регенерация", duration = 20, expiration = 1015},
                    {name = "Магический доспех", duration = 5, expiration = 1002},
                },
            }
            local list = mock[u]
            if not list or not list[i] then return nil end
            local b = list[i]
            return b.name, "icon", 1, nil, b.duration, b.expiration
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 4 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.GetExpiringBuffs
        if type(fn) ~= "function" then
            return fail("GetExpiringBuffs не является глобальной функцией")
        end

        local currentTime = 1000

        local tests = {
            {unit = "player", threshold = 10, exp = {"Ярость", "Ускорение"}},
            {unit = "player", threshold = 30, exp = {"Щит", "Ярость", "Ускорение"}},
            {unit = "target", threshold = 5, exp = {"Магический доспех"}},
            {unit = "player", threshold = 0, exp = {}},
        }

        local function formatBuffs(unit)
            local parts = {}
            local i = 1
            while true do
                local name, _, _, _, duration, expiration = UnitBuff(unit, i)
                if not name then break end
                local remaining = expiration > 0 and (expiration - currentTime) or "нет таймера"
                table.insert(parts, name .. "(" .. tostring(remaining) .. "с)")
                i = i + 1
            end
            return table.concat(parts, ", ")
        end

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.unit, test.threshold)

            local buffsInfo = formatBuffs(test.unit)
            _G["test" .. i] = "Баффы: {" .. buffsInfo .. "} | Порог: " .. test.threshold .. "с | Получено: {" .. table.concat(result or {}, ", ") .. "} | Ожидалось: {" .. table.concat(test.exp, ", ") .. "}"

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("Тест " .. i .. ": функция должна вернуть таблицу")
            end

            if #result ~= #test.exp then
                return fail("Тест " .. i .. " не пройден: не совпадает длина массива")
            end

            for j = 1, #result do
                if result[j] ~= test.exp[j] then
                    return fail("Тест " .. i .. " не пройден: элемент " .. j .. " не совпадает")
                end
            end
        end

        return true
    end,
}

ns_llua['lua'][110] = {
    type = "commenttest",
    title = "Тест 107-3: функция FindBuffContaining",
    helpModules = {107, 45, 33, 17},
    preloadVars = {
        {var = "FindBuffContaining", desc = "FindBuffContaining очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3"},
    instruction = [=[
<h>Тест 107-3: функция FindBuffContaining</h>
<t>Создай глобальную функцию <k>FindBuffContaining(unit, text)</k>.</t>
<t>Функция должна найти первый бафф на юните, в имени которого есть подстрока <k>text</k>, и вернуть его имя.</t>
<t>Если такого баффа нет, вернуть <k>nil</k>.</t>
<t>Если <k>text</k> не строка или пустая строка, вернуть <k>nil</k>.</t>
<t>Поиск должен быть регистронезависимым.</t>
<w>Перед проверкой возьми в цель любого юнита.</w>
<w>Тест проверит поиск по трём разным подстрокам.</w>
]=],
    initialCode = [=[
function FindBuffContaining(unit, text)
    
end
]=],
    requireKeywords = {
        "FindBuffContaining",
        "function",
        "UnitBuff",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        for i = 1, 3 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.FindBuffContaining) ~= "function" then
            return fail("FindBuffContaining не является глобальной функцией")
        end

        local okExists, exists = pcall(UnitExists, "target")
        if not okExists or not exists then
            return fail("Нет цели. Возьми любого юнита в цель и нажми проверку снова.")
        end

        local buffNames = {}
        local i = 1
        while true do
            local name = UnitBuff("target", i)
            if not name then break end
            table.insert(buffNames, name)
            i = i + 1
        end

        local testStrings = {}
        if #buffNames >= 2 then
            table.insert(testStrings, string.sub(buffNames[1], 1, 3))
            table.insert(testStrings, string.sub(buffNames[2], 1, 3))
            table.insert(testStrings, "zzz_nonexistent_string_zzz")
        else
            table.insert(testStrings, "")
            table.insert(testStrings, "any")
            table.insert(testStrings, "xyz")
        end

        for i, text in ipairs(testStrings) do
            local ok, result = pcall(_G.FindBuffContaining, "target", text)

            local expected = nil
            if type(text) == "string" and text ~= "" then
                local lowerText = string.lower(text)
                for _, name in ipairs(buffNames) do
                    if string.find(string.lower(name), lowerText, 1, true) then
                        expected = name
                        break
                    end
                end
            end

            _G["test" .. i] = "Подстрока '" .. text .. "' | Получено: " .. tostring(result) .. " | Ожидалось: " .. tostring(expected)

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            local resultMatch = (result == expected)
            if not resultMatch and type(result) == "string" and type(expected) == "string" then
                resultMatch = string.find(string.lower(result), string.lower(expected), 1, true) ~= nil
                    and string.find(string.lower(expected), string.lower(result), 1, true) ~= nil
            end

            if not resultMatch then
                return fail("Тест " .. i .. " не пройден")
            end
        end

        return true
    end,
}

ns_llua['lua'][111] = {
    type = "commenttest",
    title = "Тест 107-4: функция GetStrongestBuff",
    helpModules = {107, 45, 17},
    preloadVars = {
        {var = "GetStrongestBuff", desc = "GetStrongestBuff очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3"},
    instruction = [=[
<h>Тест 107-4: функция GetStrongestBuff</h>
<t>Создай глобальную функцию <k>GetStrongestBuff(unit)</k>.</t>
<t>Функция должна вернуть имя баффа с наибольшим количеством стаков (третий параметр <k>UnitBuff</k>).</t>
<t>Если у нескольких баффов одинаковое максимальное количество стаков, вернуть первый из них.</t>
<t>Если у юнита нет баффов, вернуть <k>nil</k>.</t>
<w>Во время проверки система подставит свои тестовые значения, искать юнитов не нужно.</w>
]=],
    initialCode = [=[
function GetStrongestBuff(unit)
    
end
]=],
    requireKeywords = {
        "GetStrongestBuff",
        "function",
        "UnitBuff",
        "return",
    },

    mockGlobals = {
        UnitBuff = function(u, i)
            local mock = {
                player = {
                    {name = "Щит", count = 1},
                    {name = "Ярость", count = 5},
                    {name = "Благословение", count = 3},
                },
                target = {
                    {name = "Регенерация", count = 2},
                    {name = "Магический доспех", count = 2},
                },
                empty = {},
            }
            local list = mock[u] or {}
            if not list[i] then return nil end
            local b = list[i]
            return b.name, "icon", b.count
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 3 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.GetStrongestBuff
        if type(fn) ~= "function" then
            return fail("GetStrongestBuff не является глобальной функцией")
        end

        local tests = {
            {unit = "player", exp = "Ярость", label = "Максимум 5 стаков"},
            {unit = "target", exp = "Регенерация", label = "Первый из равных (2 стаков)"},
            {unit = "empty", exp = nil, label = "Нет баффов"},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.unit)

            _G["test" .. i] = test.label .. " | Получено: " .. tostring(result) .. " | Ожидалось: " .. tostring(test.exp)

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if result ~= test.exp then
                return fail("Тест " .. i .. " не пройден")
            end
        end

        return true
    end,
}

ns_llua['lua'][112] = {
    type = "commenttest",
    title = "Тест 107-5: функция FindLowestBuffedRaidMember",
    helpModules = {107, 45, 31, 17, 7},
    preloadVars = {
        {var = "FindLowestBuffedRaidMember", desc = "FindLowestBuffedRaidMember очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 107-5: функция FindLowestBuffedRaidMember</h>
<t>Создай глобальную функцию <k>FindLowestBuffedRaidMember()</k>.</t>
<t>Функция должна найти участника рейда с наименьшим количеством баффов и вернуть одну строку в формате:</t>
<s>"Имя: Тралл, Баффов: 3"</s>
<t>Если у нескольких участников одинаковое минимальное количество баффов, вернуть первого из них (по порядку в рейде).</t>
<w>Перед проверкой собери рейд минимум из 3 человек.</w>
]=],
    initialCode = [=[
function FindLowestBuffedRaidMember()
    
end
]=],
    requireKeywords = {
        "FindLowestBuffedRaidMember",
        "function",
        "GetNumRaidMembers",
        "UnitBuff",
        "UnitName",
        "string.format",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.FindLowestBuffedRaidMember) ~= "function" then
            return fail("FindLowestBuffedRaidMember не является глобальной функцией")
        end

        local numRaid = GetNumRaidMembers()
        if numRaid < 3 then
            return fail("Нет рейда или мало игроков (" .. numRaid .. "/3). Собери рейд минимум из 3 человек и нажми проверку снова.")
        end

        local ok, result = pcall(_G.FindLowestBuffedRaidMember)

        if ok then
            _G.result = result
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова FindLowestBuffedRaidMember: " .. tostring(result))
        end
        if type(result) ~= "string" then
            return fail("Функция должна вернуть строку")
        end

        local function countBuffs(unit)
            local n = 0
            local i = 1
            while UnitBuff(unit, i) do
                n = n + 1
                i = i + 1
            end
            return n
        end

        local minBuffs = math.huge
        local minName = nil
        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitExists(unit) then
                local c = countBuffs(unit)
                if c < minBuffs then
                    minBuffs = c
                    minName = UnitName(unit) or "Unknown"
                end
            end
        end

        if not minName then
            return fail("В рейде не найдено ни одного существующего участника")
        end

        local expected = string.format("Имя: %s, Баффов: %d", minName, minBuffs)
        local name, buffs = result:match("^Имя: (.+), Баффов: (%d+)$")

        if not name then
            return fail("Строка не похожа на 'Имя: X, Баффов: Y'")
        end

        if name ~= minName then
            return fail("Имя не совпадает. Ожидалось: '" .. minName .. "', получено: '" .. name .. "'")
        end
        if tonumber(buffs) ~= minBuffs then
            return fail("Количество баффов не совпадает. Ожидалось: " .. minBuffs .. ", получено: " .. buffs)
        end

        return true
    end,
}

ns_llua['lua'][113] = {
type = "info",
title = "Группа: party1-party4",
helpModules = {71, 101},
content = [=[
<h>Группа: party1-party4</h>
<t>В группе может быть до четырёх других игроков. Их UnitID:</t>
<c>"party1"</c>
<c>"party2"</c>
<c>"party3"</c>
<c>"party4"</c>
<h>Количество участников группы</h>
<code>
/run print(GetNumPartyMembers())
</code>
<t>Если ты не в группе, функция обычно возвращает <n>0</n>.</t>
<h>Перебор группы</h>
<code>
/run for i = 1, 4 do local unit = "party" .. i; if UnitExists(unit) then print(UnitName(unit)) end end
</code>
<t>Здесь строка <s>"party"</s> склеивается с числом <k>i</k>, получаются <s>"party1"</s>, <s>"party2"</s> и так далее.</t>
<h>Лидер группы</h>
<code>
/run print(GetPartyLeaderIndex())
</code>
<t>Если лидер — первый участник группы, функция может вернуть <n>1</n>.</t>
<t>Если ты один или лидером являешься ты, функция может вернуть <n>0</n> или <k>nil</k>.</t>
<h>Проверка лидера</h>
<code>
/run local leader = GetPartyLeaderIndex(); if leader and leader > 0 then print("Лидер группы: party" .. leader) else print("Лидер не найден или ты один") end
</code>
<h>UnitInParty</h>
<code>
/run print(UnitInParty("player"))
</code>
<h>Таблица участников</h>
<code>
/run partyReport = {}; for i = 1, 4 do local unit = "party" .. i; if UnitExists(unit) then table.insert(partyReport, UnitName(unit)) end end; print("В группе:", #partyReport)
</code>
<w>Примечание:</w> если ты в рейде, используются UnitID <c>"raid1"</c> — <c>"raid40"</c>, а не <c>"party"</c>.
]=],
}

ns_llua['lua'][114] = {
    type = "commenttest",
    title = "Тест 113-1: функция GetPartyReport",
    helpModules = {113, 45, 44, 7, 17},
    preloadVars = {
        {var = "GetPartyReport", desc = "GetPartyReport очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 113-1: функция GetPartyReport</h>
<t>Создай глобальную функцию <k>GetPartyReport()</k>.</t>
<t>Функция должна собрать отчёт по всем участникам группы и вернуть массив строк.</t>
<t>Формат каждой строки:</t>
<s>"Имя: Вася, Уровень: 80, Класс: WARRIOR"</s>
<t>Перебирай юниты party1, party2, party3, party4.</t>
<t>Массив должен быть отсортирован по алфавиту имён (от А до Я).</t>
<t>Несуществующих юнитов пропускай.</t>
<w>Перед проверкой собери группу минимум из 2 человек.</w>
]=],
    initialCode = [=[
function GetPartyReport()
    
end
]=],
    requireKeywords = {
        "GetPartyReport",
        "function",
        "for",
        "UnitExists",
        "UnitName",
        "UnitLevel",
        "UnitClass",
        "table.sort",
        "string.format",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetPartyReport) ~= "function" then
            return fail("GetPartyReport не является глобальной функцией")
        end

        local numParty = GetNumPartyMembers()
        if numParty < 2 then
            return fail("Нет группы или мало игроков (" .. numParty .. "/2). Собери группу минимум из 2 человек.")
        end

        local ok, result = pcall(_G.GetPartyReport)

        if ok and type(result) == "table" then
            _G.result = result
        elseif ok then
            _G.result = "ОШИБКА: функция вернула " .. type(result)
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова GetPartyReport: " .. tostring(result))
        end
        if type(result) ~= "table" then
            return fail("GetPartyReport должна вернуть массив (таблицу)")
        end

        local expected = {}
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) then
                local name = UnitName(unit) or "Unknown"
                local level = UnitLevel(unit) or 0
                local _, classToken = UnitClass(unit)
                classToken = classToken or "UNKNOWN"

                local line = string.format("Имя: %s, Уровень: %d, Класс: %s", name, level, classToken)
                table.insert(expected, {name = name, line = line})
            end
        end

        table.sort(expected, function(a, b)
            return a.name < b.name
        end)

        if #result ~= #expected then
            return fail("Количество строк не совпадает: ожидалось " .. #expected .. ", получено " .. #result)
        end

        for i = 1, #expected do
            if result[i] ~= expected[i].line then
                return fail("Строка " .. i .. " не совпадает. Ожидалось: '" .. expected[i].line .. "', получено: '" .. tostring(result[i]) .. "'")
            end
        end

        return true
    end,
}

ns_llua['lua'][115] = {
    type = "commenttest",
    title = "Тест 113-2: функция FilterPartyByLevel",
    helpModules = {113, 45, 31, 29},
    preloadVars = {
        {var = "FilterPartyByLevel", desc = "FilterPartyByLevel очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4"},
    instruction = [=[
<h>Тест 113-2: функция FilterPartyByLevel</h>
<t>Создай глобальную функцию <k>FilterPartyByLevel(minLevel)</k>.</t>
<t>Аргумент <k>minLevel</k> — минимальный уровень.</t>
<t>Функция должна вернуть массив UnitID участников группы (party1-party4), у которых уровень больше или равен <k>minLevel</k>.</t>
<t>Порядок юнитов в результирующем массиве должен совпадать с порядком в группе.</t>
<t>Если <k>minLevel</k> не число, верни пустой массив.</t>
<w>Во время проверки система подставит свои тестовые значения, собирать группу не нужно.</w>
]=],
    initialCode = [=[
function FilterPartyByLevel(minLevel)
    
end
]=],
    requireKeywords = {
        "FilterPartyByLevel",
        "function",
        "for",
        "UnitExists",
        "UnitLevel",
        "return",
    },

    mockGlobals = {
        UnitExists = function(u)
            local mock = {
                party1 = true,
                party2 = true,
                party3 = true,
                party4 = false,
            }
            return mock[u] == true
        end,
        UnitLevel = function(u)
            local mock = {
                party1 = 80,
                party2 = 75,
                party3 = 60,
                party4 = 0,
            }
            return mock[u] or 0
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 4 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.FilterPartyByLevel
        if type(fn) ~= "function" then
            return fail("FilterPartyByLevel не является глобальной функцией")
        end

        local tests = {
            {minLevel = 70, exp = {"party1", "party2"}},
            {minLevel = 80, exp = {"party1"}},
            {minLevel = 50, exp = {"party1", "party2", "party3"}},
            {minLevel = "bad", exp = {}},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.minLevel)

            _G["test" .. i] = "Получено: {" .. table.concat(result or {}, ", ") .. "} | Ожидалось: {" .. table.concat(test.exp, ", ") .. "}"

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("Тест " .. i .. ": функция должна вернуть таблицу")
            end

            if #result ~= #test.exp then
                return fail("Тест " .. i .. " не пройден: не совпадает длина массива")
            end

            for j = 1, #result do
                if result[j] ~= test.exp[j] then
                    return fail("Тест " .. i .. " не пройден: элемент " .. j .. " не совпадает")
                end
            end
        end

        return true
    end,
}

ns_llua['lua'][116] = {
    type = "commenttest",
    title = "Тест 113-3: функция GetPartyLeaderInfo",
    helpModules = {113, 45, 17, 7},
    preloadVars = {
        {var = "GetPartyLeaderInfo", desc = "GetPartyLeaderInfo очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 113-3: функция GetPartyLeaderInfo</h>
<t>Создай глобальную функцию <k>GetPartyLeaderInfo()</k>.</t>
<t>Функция должна вернуть информацию о лидере группы в формате:</t>
<s>"Лидер: Вася, Уровень: 80"</s>
<w>Перед проверкой собери группу минимум из 2 человек.</w>
]=],
    initialCode = [=[
function GetPartyLeaderInfo()
    
end
]=],
    requireKeywords = {
        "GetPartyLeaderInfo",
        "function",
        "GetPartyLeaderIndex",
        "UnitName",
        "UnitLevel",
        "string.format",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetPartyLeaderInfo) ~= "function" then
            return fail("GetPartyLeaderInfo не является глобальной функцией")
        end

        local numParty = GetNumPartyMembers()
        if numParty < 2 then
            return fail("Нет группы или мало игроков (" .. numParty .. "/2). Собери группу минимум из 2 человек.")
        end

        local ok, result = pcall(_G.GetPartyLeaderInfo)

        if ok then
            _G.result = result
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова GetPartyLeaderInfo: " .. tostring(result))
        end
        if type(result) ~= "string" then
            return fail("Функция должна вернуть строку")
        end

        local leaderIndex = GetPartyLeaderIndex()
        local unit
        
        -- Лидер может быть самим игроком (индекс 0 в некоторых версиях API)
        -- или одним из party1-party4
        if leaderIndex and leaderIndex > 0 and leaderIndex <= 4 then
            unit = "party" .. leaderIndex
        elseif leaderIndex == 0 then
            unit = "player"
        end
        
        if not unit or not UnitExists(unit) then
            return fail("Не удалось определить лидера группы")
        end
        
        local name = UnitName(unit) or "Unknown"
        local level = UnitLevel(unit) or 0
        local expected = string.format("Лидер: %s, Уровень: %d", name, level)

        if result ~= expected then
            return fail("Результат не совпадает. Ожидалось: '" .. expected .. "', получено: '" .. result .. "'")
        end

        return true
    end,
}

ns_llua['lua'][117] = {
    type = "commenttest",
    title = "Тест 113-4: функция GetPartyStats",
    helpModules = {113, 45, 44, 31},
    preloadVars = {
        {var = "GetPartyStats", desc = "GetPartyStats очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 113-4: функция GetPartyStats</h>
<t>Создай глобальную функцию <k>GetPartyStats()</k>.</t>
<t>Функция должна вернуть таблицу со статистикой по группе:</t>
<c>total</c> — общее количество существующих участников.
<c>avgLevel</c> — средний уровень (округлённый вниз через <k>math.floor</k>).
<c>minLevel</c> — минимальный уровень.
<c>maxLevel</c> — максимальный уровень.
<t>Если в группе нет ни одного существующего участника, вернуть <s>{total = 0, avgLevel = 0, minLevel = 0, maxLevel = 0}</s>.</t>
<w>Во время проверки система подставит свои тестовые значения, собирать группу не нужно.</w>
]=],
    initialCode = [=[
function GetPartyStats()
    
end
]=],
    requireKeywords = {
        "GetPartyStats",
        "function",
        "for",
        "UnitExists",
        "UnitLevel",
        "math.floor",
        "return",
    },

    mockGlobals = {
        UnitExists = function(u)
            local mock = {
                party1 = true,
                party2 = true,
                party3 = true,
                party4 = false,
            }
            return mock[u] == true
        end,
        UnitLevel = function(u)
            local mock = {
                party1 = 80,
                party2 = 75,
                party3 = 60,
                party4 = 0,
            }
            return mock[u] or 0
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.GetPartyStats
        if type(fn) ~= "function" then
            return fail("GetPartyStats не является глобальной функцией")
        end

        local ok, result = pcall(fn)

        if ok and type(result) == "table" then
            _G.result = result
        elseif ok then
            _G.result = "ОШИБКА: функция вернула " .. type(result)
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова GetPartyStats: " .. tostring(result))
        end
        if type(result) ~= "table" then
            return fail("GetPartyStats должна вернуть таблицу")
        end

        local expected = {
            total = 3,
            avgLevel = math.floor((80 + 75 + 60) / 3),
            minLevel = 60,
            maxLevel = 80,
        }

        if result.total ~= expected.total then
            return fail("total не совпадает: ожидалось " .. expected.total .. ", получено " .. tostring(result.total))
        end
        if result.avgLevel ~= expected.avgLevel then
            return fail("avgLevel не совпадает: ожидалось " .. expected.avgLevel .. ", получено " .. tostring(result.avgLevel))
        end
        if result.minLevel ~= expected.minLevel then
            return fail("minLevel не совпадает: ожидалось " .. expected.minLevel .. ", получено " .. tostring(result.minLevel))
        end
        if result.maxLevel ~= expected.maxLevel then
            return fail("maxLevel не совпадает: ожидалось " .. expected.maxLevel .. ", получено " .. tostring(result.maxLevel))
        end

        return true
    end,
}

ns_llua['lua'][118] = {
    type = "commenttest",
    title = "Тест 113-5: функция ComparePartyMembers",
    helpModules = {113, 45, 17, 7},
    preloadVars = {
        {var = "ComparePartyMembers", desc = "ComparePartyMembers очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 113-5: функция ComparePartyMembers</h>
<t>Создай глобальную функцию <k>ComparePartyMembers(index1, index2)</k>.</t>
<t>Аргументы — индексы участников группы (числа от 1 до 4).</t>
<t>Функция должна вернуть одну строку в формате:</t>
<s>"party1: Вася (80), party2: Петя (75), Разница: 5"</s>
<t>Поля строки:</t>
<c>party1</c> — UnitID первого участника.
<c>party2</c> — UnitID второго участника.
<c>Разница</c> — абсолютная разница между уровнями.
<w>Перед проверкой собери группу минимум из 2 человек.</w>
]=],
    initialCode = [=[
function ComparePartyMembers(index1, index2)
    
end
]=],
    requireKeywords = {
        "ComparePartyMembers",
        "function",
        "UnitName",
        "UnitLevel",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.ComparePartyMembers) ~= "function" then
            return fail("ComparePartyMembers не является глобальной функцией")
        end

        local numParty = GetNumPartyMembers()
        if numParty < 2 then
            return fail("Нет группы или мало игроков (" .. numParty .. "/2). Собери группу минимум из 2 человек.")
        end

        local unit1 = "party1"
        local unit2 = "party2"

        if not UnitExists(unit1) or not UnitExists(unit2) then
            return fail("party1 или party2 не существуют. Собери группу минимум из 2 человек.")
        end

        local ok, result = pcall(_G.ComparePartyMembers, 1, 2)

        if ok then
            _G.result = result
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова ComparePartyMembers: " .. tostring(result))
        end
        if type(result) ~= "string" then
            return fail("Функция должна вернуть строку")
        end

        local name1 = UnitName(unit1) or "Unknown"
        local level1 = UnitLevel(unit1) or 0
        local name2 = UnitName(unit2) or "Unknown"
        local level2 = UnitLevel(unit2) or 0
        local diff = math.abs(level1 - level2)

        local expected = string.format("party1: %s (%d), party2: %s (%d), Разница: %d",
            name1, level1, name2, level2, diff)

        if result ~= expected then
            return fail("Результат не совпадает. Ожидалось: '" .. expected .. "', получено: '" .. result .. "'")
        end

        return true
    end,
}

ns_llua['lua'][119] = {
    type = "commenttest",
    title = "Тест: функция GetPartyClassSummary",
    helpModules = {101, 113, 45, 44},
    preloadVars = {
        {var = "GetPartyClassSummary", desc = "GetPartyClassSummary очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест: функция GetPartyClassSummary</h>
<t>Создай глобальную функцию <k>GetPartyClassSummary()</k>.</t>
<t>Функция должна собрать статистику по участникам группы и вернуть таблицу, где ключи — токены классов, а значения — количество участников этого класса.</t>
<t>Пример результата:</t>
<code>{MAGE = 2, WARRIOR = 1, PRIEST = 1}</code>
<w>Перед проверкой собери группу минимум из 2 человек.</w>
]=],
    initialCode = [=[
function GetPartyClassSummary()
    
end
]=],
    requireKeywords = {
        "GetPartyClassSummary",
        "function",
        "GetNumPartyMembers",
        "for",
        "UnitClass",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetPartyClassSummary) ~= "function" then
            return fail("GetPartyClassSummary не является глобальной функцией")
        end

        local numParty = GetNumPartyMembers()
        if numParty < 2 then
            return fail("Нет группы или мало игроков (" .. numParty .. "/2). Собери группу минимум из 2 человек.")
        end

        local ok, result = pcall(_G.GetPartyClassSummary)

        if ok and type(result) == "table" then
            _G.result = result
        elseif ok then
            _G.result = "ОШИБКА: функция вернула " .. type(result)
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова GetPartyClassSummary: " .. tostring(result))
        end
        if type(result) ~= "table" then
            return fail("GetPartyClassSummary должна вернуть таблицу")
        end

        local expected = {}
        for i = 1, numParty do
            local unit = "party" .. i
            local _, classToken = UnitClass(unit)
            expected[classToken] = (expected[classToken] or 0) + 1
        end

        local expectedCount = 0
        for _ in pairs(expected) do expectedCount = expectedCount + 1 end

        local resultCount = 0
        for _ in pairs(result) do resultCount = resultCount + 1 end

        if resultCount ~= expectedCount then
            return fail("Количество классов не совпадает: ожидалось " .. expectedCount .. ", получено " .. resultCount)
        end

        for classToken, count in pairs(expected) do
            if result[classToken] ~= count then
                return fail("Для класса " .. classToken .. " ожидалось " .. count .. ", получено " .. tostring(result[classToken]))
            end
        end

        return true
    end,
}

ns_llua['lua'][120] = {
    type = "commenttest",
    title = "Тест: функция FindDebuffedUnits",
    helpModules = {107, 45, 31, 29},
    preloadVars = {
        {var = "FindDebuffedUnits", desc = "FindDebuffedUnits очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4"},
    instruction = [=[
<h>Тест: функция FindDebuffedUnits</h>
<t>Создай глобальную функцию <k>FindDebuffedUnits(units)</k>.</t>
<t>Аргумент <k>units</k> — массив строк UnitID.</t>
<t>Функция должна вернуть новый массив, содержащий только тех юнитов, у которых есть хотя бы один дебафф.</t>
<t>Порядок юнитов в результирующем массиве должен совпадать с исходным.</t>
<t>Если аргумент не таблица, верни пустой массив.</t>
<w>Во время проверки система подставит свои тестовые значения, искать юнитов не нужно.</w>
]=],
    initialCode = [=[
function FindDebuffedUnits(units)
    
end
]=],
    requireKeywords = {
        "FindDebuffedUnits",
        "function",
        "for",
        "UnitDebuff",
        "return",
    },

    mockGlobals = {
        UnitDebuff = function(u, i)
            local mock = {
                debuff1 = {"Яд"},
                debuff2 = {"Замедление", "Боль"},
                clean = {},
                missing = {},
            }
            local list = mock[u] or {}
            if not list[i] then return nil end
            return list[i]
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 4 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.FindDebuffedUnits
        if type(fn) ~= "function" then
            return fail("FindDebuffedUnits не является глобальной функцией")
        end

        local tests = {
            {input = {"debuff1", "clean", "debuff2"}, exp = {"debuff1", "debuff2"}},
            {input = {"clean", "clean"}, exp = {}},
            {input = {"debuff1", "debuff2"}, exp = {"debuff1", "debuff2"}},
            {input = "bad", exp = {}},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.input)

            _G["test" .. i] = "Получено: {" .. table.concat(result or {}, ", ") .. "} | Ожидалось: {" .. table.concat(test.exp, ", ") .. "}"

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("Тест " .. i .. ": функция должна вернуть таблицу")
            end

            if #result ~= #test.exp then
                return fail("Тест " .. i .. " не пройден: не совпадает длина массива")
            end

            for j = 1, #result do
                if result[j] ~= test.exp[j] then
                    return fail("Тест " .. i .. " не пройден: элемент " .. j .. " не совпадает")
                end
            end
        end

        return true
    end,
}

ns_llua['lua'][121] = {
    type = "commenttest",
    title = "Тест: функция SortPartyByLevel",
    helpModules = {113, 101, 45, 44, 7},
    preloadVars = {
        {var = "SortPartyByLevel", desc = "SortPartyByLevel очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест: функция SortPartyByLevel</h>
<t>Создай глобальную функцию <k>SortPartyByLevel()</k>.</t>
<t>Функция должна отсортировать участников группы по уровню (от старшего к младшему) и вернуть массив строк в формате:</t>
<s>"party1: Вася (80)"</s>
<s>"party2: Петя (75)"</s>
<s>"party3: Сидр (60)"</s>
<t>Если у двух участников одинаковый уровень, сохранить исходный порядок.</t>
<w>Перед проверкой собери группу минимум из 2 человек.</w>
]=],
    initialCode = [=[
function SortPartyByLevel()
    
end
]=],
    requireKeywords = {
        "SortPartyByLevel",
        "function",
        "GetNumPartyMembers",
        "for",
        "UnitName",
        "UnitLevel",
        "table.sort",
        "string.format",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.SortPartyByLevel) ~= "function" then
            return fail("SortPartyByLevel не является глобальной функцией")
        end

        local numParty = GetNumPartyMembers()
        if numParty < 2 then
            return fail("Нет группы или мало игроков (" .. numParty .. "/2). Собери группу минимум из 2 человек.")
        end

        local ok, result = pcall(_G.SortPartyByLevel)

        if ok and type(result) == "table" then
            _G.result = result
        elseif ok then
            _G.result = "ОШИБКА: функция вернула " .. type(result)
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова SortPartyByLevel: " .. tostring(result))
        end
        if type(result) ~= "table" then
            return fail("SortPartyByLevel должна вернуть массив (таблицу)")
        end

        local expected = {}
        for i = 1, numParty do
            local unit = "party" .. i
            local name = UnitName(unit) or "Unknown"
            local level = UnitLevel(unit) or 0
            local line = string.format("%s: %s (%d)", unit, name, level)
            table.insert(expected, {unit = unit, level = level, line = line})
        end

        table.sort(expected, function(a, b)
            return a.level > b.level
        end)

        if #result ~= #expected then
            return fail("Количество строк не совпадает: ожидалось " .. #expected .. ", получено " .. #result)
        end

        for i = 1, #expected do
            if result[i] ~= expected[i].line then
                return fail("Строка " .. i .. " не совпадает. Ожидалось: '" .. expected[i].line .. "', получено: '" .. tostring(result[i]) .. "'")
            end
        end

        return true
    end,
}

ns_llua['lua'][122] = {
    type = "commenttest",
    title = "Тест: функция DescribeAttackableUnits",
    helpModules = {95, 101, 45, 31, 44},
    preloadVars = {
        {var = "DescribeAttackableUnits", desc = "DescribeAttackableUnits очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3"},
    instruction = [=[
<h>Тест: функция DescribeAttackableUnits</h>
<t>Создай глобальную функцию <k>DescribeAttackableUnits(units)</k>.</t>
<t>Аргумент <k>units</k> — массив строк UnitID.</t>
<t>Функция должна отфильтровать только тех юнитов, которых игрок может атаковать, и вернуть массив таблиц с описанием каждого.</t>
<t>Каждая таблица должна содержать поля:</t>
<c>name</c> — имя юнита.
<c>level</c> — уровень юнита.
<c>classToken</c> — токен класса юнита.
<t>Порядок юнитов в результирующем массиве должен совпадать с исходным.</t>
<t>Если аргумент не таблица, верни пустой массив.</t>
<w>Во время проверки система подставит свои тестовые значения, искать юнитов не нужно.</w>
]=],
    initialCode = [=[
function DescribeAttackableUnits(units)
    
end
]=],
    requireKeywords = {
        "DescribeAttackableUnits",
        "function",
        "for",
        "UnitCanAttack",
        "UnitName",
        "UnitLevel",
        "UnitClass",
        "return",
    },

    mockGlobals = {
        UnitCanAttack = function(attacker, u)
            local mock = {
                enemy1 = true,
                enemy2 = true,
                friend1 = false,
                neutral = false,
            }
            return mock[u] == true
        end,
        UnitName = function(u)
            local mock = {
                enemy1 = "Злодей",
                enemy2 = "Бандит",
                friend1 = "Друг",
                neutral = "Нейтрал",
            }
            return mock[u]
        end,
        UnitLevel = function(u)
            local mock = {
                enemy1 = 80,
                enemy2 = 75,
                friend1 = 80,
                neutral = 70,
            }
            return mock[u]
        end,
        UnitClass = function(u)
            local mock = {
                enemy1 = {"Воин", "WARRIOR"},
                enemy2 = {"Разбойник", "ROGUE"},
                friend1 = {"Маг", "MAGE"},
                neutral = {"Охотник", "HUNTER"},
            }
            local data = mock[u]
            if not data then return nil, nil end
            return data[1], data[2]
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 3 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.DescribeAttackableUnits
        if type(fn) ~= "function" then
            return fail("DescribeAttackableUnits не является глобальной функцией")
        end

        local tests = {
            {input = {"enemy1", "friend1", "enemy2"}, exp = {
                {name = "Злодей", level = 80, classToken = "WARRIOR"},
                {name = "Бандит", level = 75, classToken = "ROGUE"},
            }},
            {input = {"friend1", "neutral"}, exp = {}},
            {input = "bad", exp = {}},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.input)

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("Тест " .. i .. ": функция должна вернуть таблицу")
            end

            if #result ~= #test.exp then
                return fail("Тест " .. i .. " не пройден: ожидалось " .. #test.exp .. " элементов, получено " .. #result)
            end

            for j = 1, #result do
                local r = result[j]
                local e = test.exp[j]
                if type(r) ~= "table" then
                    return fail("Тест " .. i .. ": элемент " .. j .. " должен быть таблицей")
                end
                if r.name ~= e.name then
                    return fail("Тест " .. i .. ": элемент " .. j .. ", name не совпадает")
                end
                if r.level ~= e.level then
                    return fail("Тест " .. i .. ": элемент " .. j .. ", level не совпадает")
                end
                if r.classToken ~= e.classToken then
                    return fail("Тест " .. i .. ": элемент " .. j .. ", classToken не совпадает")
                end
            end

            _G["test" .. i] = "Пройден: " .. #result .. " элементов"
        end

        return true
    end,
}

ns_llua['lua'][123] = {
    type = "commenttest",
    title = "Тест: функция GetRaidOnlineReport",
    helpModules = {101, 45, 17, 7, 44},
    preloadVars = {
        {var = "GetRaidOnlineReport", desc = "GetRaidOnlineReport очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест: функция GetRaidOnlineReport</h>
<t>Создай глобальную функцию <k>GetRaidOnlineReport()</k>.</t>
<t>Функция должна собрать отчёт по всем участникам рейда и вернуть массив строк в формате:</t>
<s>"Имя: Вася, Уровень: 80, Класс: WARRIOR, Статус: онлайн"</s>
<s>"Имя: Петя, Уровень: 75, Класс: MAGE, Статус: офлайн"</s>
<t>Порядок вывода:</t>
<t>1. Сначала все онлайновые участники, отсортированные по уровню (от старшего к младшему). При равном уровне — по алфавиту токена класса.</t>
<t>2. Затем все офлайновые участники, отсортированные по тем же правилам.</t>
<w>Перед проверкой собери рейд минимум из 3 человек.</w>
]=],
    initialCode = [=[
function GetRaidOnlineReport()
    
end
]=],
    requireKeywords = {
        "GetRaidOnlineReport",
        "function",
        "GetNumRaidMembers",
        "for",
        "UnitName",
        "UnitLevel",
        "UnitClass",
        "UnitIsConnected",
        "table.sort",
        "string.format",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetRaidOnlineReport) ~= "function" then
            return fail("GetRaidOnlineReport не является глобальной функцией")
        end

        local numRaid = GetNumRaidMembers()
        if numRaid < 3 then
            return fail("Нет рейда или мало игроков (" .. numRaid .. "/3). Собери рейд минимум из 3 человек.")
        end

        local ok, result = pcall(_G.GetRaidOnlineReport)

        if ok and type(result) == "table" then
            _G.result = result
        elseif ok then
            _G.result = "ОШИБКА: функция вернула " .. type(result)
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова GetRaidOnlineReport: " .. tostring(result))
        end
        if type(result) ~= "table" then
            return fail("GetRaidOnlineReport должна вернуть массив (таблицу)")
        end

        local online = {}
        local offline = {}

        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitExists(unit) then
                local name = UnitName(unit) or "Unknown"
                local level = UnitLevel(unit) or 0
                local _, classToken = UnitClass(unit)
                classToken = classToken or "UNKNOWN"
                local isOnline = UnitIsConnected(unit)

                local entry = {
                    name = name,
                    level = level,
                    classToken = classToken,
                    status = isOnline and "онлайн" or "офлайн",
                }

                if isOnline then
                    table.insert(online, entry)
                else
                    table.insert(offline, entry)
                end
            end
        end

        local function sortByLevelAndClass(a, b)
            if a.level ~= b.level then
                return a.level > b.level
            end
            return a.classToken < b.classToken
        end

        table.sort(online, sortByLevelAndClass)
        table.sort(offline, sortByLevelAndClass)

        local expected = {}
        for _, entry in ipairs(online) do
            local line = string.format("Имя: %s, Уровень: %d, Класс: %s, Статус: %s",
                entry.name, entry.level, entry.classToken, entry.status)
            table.insert(expected, line)
        end
        for _, entry in ipairs(offline) do
            local line = string.format("Имя: %s, Уровень: %d, Класс: %s, Статус: %s",
                entry.name, entry.level, entry.classToken, entry.status)
            table.insert(expected, line)
        end

        if #result ~= #expected then
            return fail("Количество строк не совпадает: ожидалось " .. #expected .. ", получено " .. #result)
        end

        for i = 1, #expected do
            if result[i] ~= expected[i] then
                return fail("Строка " .. i .. " не совпадает. Ожидалось: '" .. expected[i] .. "', получено: '" .. tostring(result[i]) .. "'")
            end
        end

        return true
    end,
}

ns_llua['lua'][124] = {
    type = "commenttest",
    title = "Тест: функция GetHealingPriorityReport",
    helpModules = {89, 107, 45, 31, 44},
    preloadVars = {
        {var = "GetHealingPriorityReport", desc = "GetHealingPriorityReport очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3"},
    instruction = [=[
<h>Тест: функция GetHealingPriorityReport</h>
<t>Создай глобальную функцию <k>GetHealingPriorityReport(units)</k>.</t>
<t>Аргумент <k>units</k> — массив строк UnitID.</t>
<t>Функция должна оценить состояние каждого существующего юнита и вернуть массив таблиц, отсортированный по проценту здоровья (по возрастанию — кто в худшем состоянии, тот первый).</t>
<t>Каждая таблица должна содержать поля:</t>
<c>unit</c> — UnitID юнита (строка).
<c>hpPercent</c> — процент здоровья (число от 0 до 100, округлённое вниз через <k>math.floor</k>).
<c>debuffCount</c> — количество дебаффов на юните (число).
<t>Несуществующих юнитов пропускай.</t>
<t>Если у юнита максимальное здоровье 0 или меньше, процент считать равным 0.</t>
<t>Если аргумент не таблица, верни пустой массив.</t>
<w>Во время проверки система подставит свои тестовые значения, искать юнитов не нужно.</w>
]=],
    initialCode = [=[
function GetHealingPriorityReport(units)
    
end
]=],
    requireKeywords = {
        "GetHealingPriorityReport",
        "function",
        "for",
        "UnitExists",
        "UnitHealth",
        "UnitHealthMax",
        "UnitDebuff",
        "math.floor",
        "table.sort",
        "return",
    },

    mockGlobals = {
        UnitExists = function(u)
            local mock = {
                tank = true,
                healer = true,
                dps1 = true,
                dps2 = true,
                dead = true,
                missing = false,
            }
            return mock[u] == true
        end,
        UnitHealth = function(u)
            local mock = {
                tank = 5000,
                healer = 1000,
                dps1 = 3000,
                dps2 = 200,
                dead = 0,
            }
            return mock[u] or 0
        end,
        UnitHealthMax = function(u)
            local mock = {
                tank = 10000,
                healer = 4000,
                dps1 = 6000,
                dps2 = 2000,
                dead = 5000,
            }
            return mock[u] or 0
        end,
        UnitDebuff = function(u, i)
            local mock = {
                tank = {"Яд", "Замедление", "Боль"},
                healer = {"Замедление"},
                dps1 = {},
                dps2 = {"Яд", "Проклятие"},
                dead = {},
            }
            local list = mock[u] or {}
            if not list[i] then return nil end
            return list[i]
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 3 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.GetHealingPriorityReport
        if type(fn) ~= "function" then
            return fail("GetHealingPriorityReport не является глобальной функцией")
        end

        -- Локальные моки для checkCode (те же что и в mockGlobals)
        local function mockUnitExists(u)
            local mock = {
                tank = true, healer = true, dps1 = true, dps2 = true,
                dead = true, missing = false,
            }
            return mock[u] == true
        end

        local function mockUnitHealth(u)
            local mock = {
                tank = 5000, healer = 1000, dps1 = 3000, dps2 = 200, dead = 0,
            }
            return mock[u] or 0
        end

        local function mockUnitHealthMax(u)
            local mock = {
                tank = 10000, healer = 4000, dps1 = 6000, dps2 = 2000, dead = 5000,
            }
            return mock[u] or 0
        end

        local function mockUnitDebuff(u, i)
            local mock = {
                tank = {"Яд", "Замедление", "Боль"},
                healer = {"Замедление"},
                dps1 = {},
                dps2 = {"Яд", "Проклятие"},
                dead = {},
            }
            local list = mock[u] or {}
            if not list[i] then return nil end
            return list[i]
        end

        local function countDebuffs(unit)
            local n, i = 0, 1
            while mockUnitDebuff(unit, i) do
                n = n + 1
                i = i + 1
            end
            return n
        end

        local function calcHpPercent(unit)
            local cur = mockUnitHealth(unit) or 0
            local max = mockUnitHealthMax(unit) or 0
            if max <= 0 then return 0 end
            return math.floor(cur / max * 100)
        end

        local tests = {
            {
                input = {"tank", "healer", "dps1", "dps2"},
                label = "Четыре живых юнита",
            },
            {
                input = {"tank", "dead", "dps2"},
                label = "Есть мёртвый юнит (HP 0%)",
            },
            {
                input = "bad",
                label = "Некорректный ввод",
            },
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.input)

            if not ok then
                return fail("Тест " .. i .. " (" .. test.label .. "): ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("Тест " .. i .. " (" .. test.label .. "): функция должна вернуть таблицу")
            end

            local expected = {}
            if type(test.input) == "table" then
                for _, unit in ipairs(test.input) do
                    if mockUnitExists(unit) then
                        local hp = calcHpPercent(unit)
                        local debuffs = countDebuffs(unit)
                        table.insert(expected, {unit = unit, hpPercent = hp, debuffCount = debuffs})
                    end
                end
                table.sort(expected, function(a, b) return a.hpPercent < b.hpPercent end)
            end

            _G["test" .. i] = test.label .. " | Получено: " .. #result .. " | Ожидалось: " .. #expected

            if #result ~= #expected then
                return fail("Тест " .. i .. " (" .. test.label .. "): не совпадает длина массива")
            end

            for j = 1, #result do
                local r = result[j]
                local e = expected[j]
                if type(r) ~= "table" then
                    return fail("Тест " .. i .. ": элемент " .. j .. " должен быть таблицей")
                end
                if r.unit ~= e.unit then
                    return fail("Тест " .. i .. ": элемент " .. j .. ", unit не совпадает. Ожидалось '" .. e.unit .. "', получено '" .. tostring(r.unit) .. "'")
                end
                if r.hpPercent ~= e.hpPercent then
                    return fail("Тест " .. i .. ": элемент " .. j .. " (" .. e.unit .. "), hpPercent не совпадает. Ожидалось " .. e.hpPercent .. ", получено " .. tostring(r.hpPercent))
                end
                if r.debuffCount ~= e.debuffCount then
                    return fail("Тест " .. i .. ": элемент " .. j .. " (" .. e.unit .. "), debuffCount не совпадает. Ожидалось " .. e.debuffCount .. ", получено " .. tostring(r.debuffCount))
                end
            end
        end

        return true
    end,
}

ns_llua['lua'][125] = {
type = "info",
title = "Лидерство, роли и лут",
helpModules = {113, 119},
content = [=[
<h>Лидерство, роли и лут</h>
<t>Эти функции помогают понять, кто главный в группе или рейде, а также как распределяется добыча.</t>
<h>Лидер группы</h>
<code>
/run print(GetPartyLeaderIndex())
</code>
<t>Если лидер группы — первый участник, функция может вернуть <n>1</n>.</t>
<t>Если ты один или лидером являешься ты, функция может вернуть <n>0</n> или <k>nil</k>.</t>
<h>Лидер рейда</h>
<code>
/run print(GetRaidLeaderIndex())
</code>
<h>Проверка лидера группы</h>
<code>
/run local leader = GetPartyLeaderIndex(); if leader and leader > 0 then print("Лидер группы: party" .. leader) else print("Лидер не найден") end
</code>
<h>UnitIsPartyLeader</h>
<code>
/run print(UnitIsPartyLeader("player"))
</code>
<h>UnitIsRaidOfficer</h>
<t>Проверяет, является ли юнит помощником лидера рейда.</t>
<code>
/run print(UnitIsRaidOfficer("player"))
</code>
<h>Метод распределения лута</h>
<code>
/run local method, master, threshold = GetLootMethod(); print(method, master, threshold)
</code>
<t>Первое значение — строка с методом лута, например:</t>
<c>"freeforall"</c>
<c>"roundrobin"</c>
<c>"master"</c>
<c>"group"</c>
<c>"needbeforegreed"</c>
<h>Порог качества лута</h>
<code>
/run local method, master, threshold = GetLootMethod(); print("Порог:", threshold)
</code>
<w>Примечание:</w> числовое значение порога связано с качеством предмета. Чем выше число, тем выше минимальное качество для розыгрыша.
<h>Безопасный шаблон</h>
<code>
/run local method = GetLootMethod() or "unknown"; print("Метод лута:", method)
</code>
]=],
}

ns_llua['lua'][126] = {
    type = "commenttest",
    title = "Тест 125-1: функция GetLeadersAndOfficers",
    helpModules = {125, 45, 31, 29},
    preloadVars = {
        {var = "GetLeadersAndOfficers", desc = "GetLeadersAndOfficers очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4"},
    instruction = [=[
<h>Тест 125-1: функция GetLeadersAndOfficers</h>
<t>Создай глобальную функцию <k>GetLeadersAndOfficers(units)</k>.</t>
<t>Аргумент <k>units</k> — массив строк UnitID.</t>
<t>Функция должна вернуть новый массив, содержащий только тех юнитов, которые являются лидером группы или помощником лидера рейда.</t>
<t>Порядок юнитов в результирующем массиве должен совпадать с исходным.</t>
<t>Если аргумент не таблица, верни пустой массив.</t>
<w>Во время проверки система подставит свои тестовые значения, искать юнитов не нужно.</w>
]=],
    initialCode = [=[
function GetLeadersAndOfficers(units)
    
end
]=],
    requireKeywords = {
        "GetLeadersAndOfficers",
        "function",
        "for",
        "UnitIsPartyLeader",
        "UnitIsRaidOfficer",
        "return",
    },

    mockGlobals = {
        UnitIsPartyLeader = function(u)
            local mock = {
                leader1 = true, leader2 = false,
                officer1 = false, officer2 = false,
                regular1 = false, regular2 = false,
            }
            return mock[u] == true
        end,
        UnitIsRaidOfficer = function(u)
            local mock = {
                leader1 = false, leader2 = false,
                officer1 = true, officer2 = true,
                regular1 = false, regular2 = false,
            }
            return mock[u] == true
        end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 4 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.GetLeadersAndOfficers
        if type(fn) ~= "function" then
            return fail("GetLeadersAndOfficers не является глобальной функцией")
        end

        local tests = {
            {input = {"leader1", "officer1", "regular1"}, exp = {"leader1", "officer1"}},
            {input = {"regular1", "leader1", "regular2"}, exp = {"leader1"}},
            {input = {"officer1", "officer2"}, exp = {"officer1", "officer2"}},
            {input = "bad", exp = {}},
        }

        for i, test in ipairs(tests) do
            local ok, result = pcall(fn, test.input)

            _G["test" .. i] = "Получено: {" .. table.concat(result or {}, ", ") .. "} | Ожидалось: {" .. table.concat(test.exp, ", ") .. "}"

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("Тест " .. i .. ": функция должна вернуть таблицу")
            end

            if #result ~= #test.exp then
                return fail("Тест " .. i .. " не пройден: не совпадает длина массива")
            end

            for j = 1, #result do
                if result[j] ~= test.exp[j] then
                    return fail("Тест " .. i .. " не пройден: элемент " .. j .. " не совпадает")
                end
            end
        end

        return true
    end,
}

ns_llua['lua'][127] = {
    type = "commenttest",
    title = "Тест 125-2: функция GetLeaderReport",
    helpModules = {125, 45, 17, 7},
    preloadVars = {
        {var = "GetLeaderReport", desc = "GetLeaderReport очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 125-2: функция GetLeaderReport</h>
<t>Создай глобальную функцию <k>GetLeaderReport()</k>.</t>
<t>Функция должна определить, где ты сейчас (в группе или рейде), и вернуть информацию о лидере в формате:</t>
<s>"Лидер: Вася, Класс: WARRIOR"</s>
<t>Если ты в рейде, используй <k>GetRaidLeaderIndex()</k> и юнит вида <s>"raid1"</s>.</t>
<t>Если ты в группе, используй <k>GetPartyLeaderIndex()</k> и юнит вида <s>"party1"</s>.</t>
<t>Если лидером являешься ты сам (индекс равен 0 или юнит "player"), используй юнит <s>"player"</s>.</t>
<t>Если лидера нет или индекс меньше либо равен нулю, вернуть строку:</t>
<s>"Лидер не найден"</s>
<w>Перед проверкой собери группу или рейд.</w>
]=],
    initialCode = [=[
function GetLeaderReport()
    
end
]=],
    requireKeywords = {
        "GetLeaderReport",
        "function",
        "GetNumRaidMembers",
        "GetPartyLeaderIndex",
        "GetRaidLeaderIndex",
        "UnitName",
        "UnitClass",
        "string.format",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetLeaderReport) ~= "function" then
            return fail("GetLeaderReport не является глобальной функцией")
        end

        local ok, result = pcall(_G.GetLeaderReport)

        if ok then
            _G.result = result
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова GetLeaderReport: " .. tostring(result))
        end
        if type(result) ~= "string" then
            return fail("Функция должна вернуть строку")
        end

        local expected
        local numRaid = GetNumRaidMembers() or 0

        if numRaid > 0 then
            local idx = GetRaidLeaderIndex()
            if idx and idx > 0 then
                local unit = "raid" .. idx
                if UnitExists(unit) then
                    local name = UnitName(unit) or "Unknown"
                    local _, classToken = UnitClass(unit)
                    classToken = classToken or "UNKNOWN"
                    expected = string.format("Лидер: %s, Класс: %s", name, classToken)
                end
            elseif idx == 0 then
                local name = UnitName("player") or "Unknown"
                local _, classToken = UnitClass("player")
                classToken = classToken or "UNKNOWN"
                expected = string.format("Лидер: %s, Класс: %s", name, classToken)
            end
        else
            local numParty = GetNumPartyMembers() or 0
            if numParty > 0 then
                local idx = GetPartyLeaderIndex()
                if idx and idx > 0 then
                    local unit = "party" .. idx
                    if UnitExists(unit) then
                        local name = UnitName(unit) or "Unknown"
                        local _, classToken = UnitClass(unit)
                        classToken = classToken or "UNKNOWN"
                        expected = string.format("Лидер: %s, Класс: %s", name, classToken)
                    end
                elseif idx == 0 then
                    local name = UnitName("player") or "Unknown"
                    local _, classToken = UnitClass("player")
                    classToken = classToken or "UNKNOWN"
                    expected = string.format("Лидер: %s, Класс: %s", name, classToken)
                end
            end
        end

        expected = expected or "Лидер не найден"

        if result ~= expected then
            return fail("Результат не совпадает. Ожидалось: '" .. expected .. "', получено: '" .. result .. "'")
        end

        return true
    end,
}

ns_llua['lua'][128] = {
    type = "commenttest",
    title = "Тест 125-3: функция GetLootSummary",
    helpModules = {125, 45, 44},
    preloadVars = {
        {var = "GetLootSummary", desc = "GetLootSummary очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 125-3: функция GetLootSummary</h>
<t>Создай глобальную функцию <k>GetLootSummary()</k>.</t>
<t>Функция должна вернуть таблицу с информацией о методе распределения лута:</t>
<c>method</c> — строка с методом (например, <s>"master"</s>, <s>"group"</s>).
<c>masterName</c> — имя мастера лута (строка) или <k>nil</k>, если мастера нет.
<c>threshold</c> — числовое значение порога качества.
<t>Используй:</t>
<c>GetLootMethod()</c> — возвращает три значения: метод, индекс мастера, порог.
<t>Если индекс мастера существует и больше нуля, получи имя через <k>UnitName("party" .. index)</k> или <k>UnitName("raid" .. index)</k>.</t>
<t>Если имя мастера получить не удалось, используй <k>nil</k>.</t>
<w>Во время проверки система подставит свои тестовые значения.</w>
]=],
    initialCode = [=[
function GetLootSummary()
    
end
]=],
    requireKeywords = {
        "GetLootSummary",
        "function",
        "GetLootMethod",
        "UnitName",
        "return",
    },

    mockGlobals = {
        GetLootMethod = function()
            return "master", 2, 3
        end,
        UnitName = function(u)
            local mock = {
                party2 = "Мастер",
                raid2 = "Мастер",
                player = "Я",
            }
            return mock[u]
        end,
        GetNumRaidMembers = function() return 0 end,
        GetNumPartyMembers = function() return 4 end,
    },

    checkCode = function(env)
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.GetLootSummary
        if type(fn) ~= "function" then
            return fail("GetLootSummary не является глобальной функцией")
        end

        local ok, result = pcall(fn)

        if ok and type(result) == "table" then
            _G.result = result
        elseif ok then
            _G.result = "ОШИБКА: функция вернула " .. type(result)
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова GetLootSummary: " .. tostring(result))
        end
        if type(result) ~= "table" then
            return fail("GetLootSummary должна вернуть таблицу")
        end

        if result.method ~= "master" then
            return fail("method не совпадает: ожидалось 'master', получено '" .. tostring(result.method) .. "'")
        end
        if result.masterName ~= "Мастер" then
            return fail("masterName не совпадает: ожидалось 'Мастер', получено '" .. tostring(result.masterName) .. "'")
        end
        if result.threshold ~= 3 then
            return fail("threshold не совпадает: ожидалось 3, получено " .. tostring(result.threshold))
        end

        return true
    end,
}

ns_llua['lua'][129] = {
    type = "commenttest",
    title = "Тест 125-4: функция GetRaidOfficers",
    helpModules = {125, 45, 44, 7},
    preloadVars = {
        {var = "GetRaidOfficers", desc = "GetRaidOfficers очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "result", desc = "result очищается перед проверкой"},
    },
    reportVars = {"checkError", "result"},
    instruction = [=[
<h>Тест 125-4: функция GetRaidOfficers</h>
<t>Создай глобальную функцию <k>GetRaidOfficers()</k>.</t>
<t>Функция должна найти всех помощников лидера рейда и вернуть массив строк в формате:</t>
<s>"Вася (WARRIOR)"</s>
<t>Массив должен быть отсортирован по алфавиту имён (от А до Я).</t>
<w>Перед проверкой собери рейд минимум из 3 человек и назначь хотя бы одного офицера.</w>
]=],
    initialCode = [=[
function GetRaidOfficers()
    
end
]=],
    requireKeywords = {
        "GetRaidOfficers",
        "function",
        "GetNumRaidMembers",
        "for",
        "UnitIsRaidOfficer",
        "UnitName",
        "UnitClass",
        "table.sort",
        "string.format",
        "return",
    },
    checkCode = function()
        _G.checkError = nil
        _G.result = nil

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(_G.GetRaidOfficers) ~= "function" then
            return fail("GetRaidOfficers не является глобальной функцией")
        end

        local numRaid = GetNumRaidMembers()
        if numRaid < 3 then
            return fail("Нет рейда или мало игроков (" .. numRaid .. "/3). Собери рейд минимум из 3 человек.")
        end

        local officerCount = 0
        for i = 1, numRaid do
            if UnitIsRaidOfficer("raid" .. i) then
                officerCount = officerCount + 1
            end
        end
        if officerCount == 0 then
            return fail("В рейде нет ни одного офицера. Назначь хотя бы одного.")
        end

        local ok, result = pcall(_G.GetRaidOfficers)

        if ok and type(result) == "table" then
            _G.result = result
        elseif ok then
            _G.result = "ОШИБКА: функция вернула " .. type(result)
        else
            _G.result = "ОШИБКА: " .. tostring(result)
        end

        if not ok then
            return fail("Ошибка вызова GetRaidOfficers: " .. tostring(result))
        end
        if type(result) ~= "table" then
            return fail("GetRaidOfficers должна вернуть массив (таблицу)")
        end

        local expected = {}
        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitExists(unit) and UnitIsRaidOfficer(unit) then
                local name = UnitName(unit) or "Unknown"
                local _, classToken = UnitClass(unit)
                classToken = classToken or "UNKNOWN"
                local line = string.format("%s (%s)", name, classToken)
                table.insert(expected, {name = name, line = line})
            end
        end

        table.sort(expected, function(a, b) return a.name < b.name end)

        if #result ~= #expected then
            return fail("Количество офицеров не совпадает: ожидалось " .. #expected .. ", получено " .. #result)
        end

        for i = 1, #expected do
            if result[i] ~= expected[i].line then
                return fail("Строка " .. i .. " не совпадает. Ожидалось: '" .. expected[i].line .. "', получено: '" .. tostring(result[i]) .. "'")
            end
        end

        return true
    end,
}

ns_llua['lua'][130] = {
    type = "commenttest",
    title = "Тест 125-5: функция WhoCanLoot",
    helpModules = {125, 45, 31, 29, 17},
    preloadVars = {
        {var = "WhoCanLoot", desc = "WhoCanLoot очищается перед проверкой"},
        {var = "checkError", desc = "checkError очищается перед проверкой"},
        {var = "test1", desc = "test1 очищается перед проверкой"},
        {var = "test2", desc = "test2 очищается перед проверкой"},
        {var = "test3", desc = "test3 очищается перед проверкой"},
        {var = "test4", desc = "test4 очищается перед проверкой"},
    },
    reportVars = {"checkError", "test1", "test2", "test3", "test4"},
    instruction = [=[
<h>Тест 125-5: функция WhoCanLoot</h>
<t>Создай глобальную функцию <k>WhoCanLoot(units)</k>.</t>
<t>Аргумент <k>units</k> — массив строк UnitID.</t>
<t>Функция должна определить, кто из юнитов может лутать в зависимости от текущего метода лута, и вернуть новый массив UnitID.</t>
<t>Логика:</t>
<c>Если метод <s>"freeforall"</s></c> — лутать могут все (вернуть весь исходный массив).
<c>Если метод <s>"master"</s></c> — лутать может только мастер. Имя мастера получи через <k>UnitName("party" .. masterIndex)</k> или <k>UnitName("raid" .. masterIndex)</k>. Верни массив с одним элементом — UnitID мастера. Если в массиве <k>units</k> нет мастера, верни пустой массив.
<c>В остальных случаях</c> (<s>"roundrobin"</s>, <s>"group"</s>, <s>"needbeforegreed"</s>) — лутать могут все (вернуть весь исходный массив).
<t>Порядок юнитов в результирующем массиве должен совпадать с исходным.</t>
<t>Если аргумент не таблица, верни пустой массив.</t>
<w>Во время проверки система подставит свои тестовые значения.</w>
]=],
    initialCode = [=[
function WhoCanLoot(units)
    
end
]=],
    requireKeywords = {
        "WhoCanLoot",
        "function",
        "GetLootMethod",
        "UnitName",
        "for",
        "return",
    },

    mockGlobals = {
        GetLootMethod = function()
            local scenario = _G._currentTestScenario or "group"
            if scenario == "freeforall" then
                return "freeforall", nil, 2
            elseif scenario == "master" then
                return "master", 2, 3
            else
                return "group", nil, 2
            end
        end,
        UnitName = function(u)
            local mock = {
                player = "Я",
                party1 = "Вася",
                party2 = "Петя",
                party3 = "Сидр",
                party4 = "Коля",
            }
            return mock[u]
        end,
        GetNumRaidMembers = function() return 0 end,
        GetNumPartyMembers = function() return 4 end,
    },

    checkCode = function(env)
        _G.checkError = nil
        for i = 1, 4 do _G["test" .. i] = nil end

        local function fail(msg)
            _G.checkError = msg
            return msg
        end

        if type(env) ~= "table" then
            return fail("Внутренняя ошибка: окружение не передано")
        end

        local fn = env.WhoCanLoot
        if type(fn) ~= "function" then
            return fail("WhoCanLoot не является глобальной функцией")
        end

        local scenarios = {
            {
                name = "freeforall",
                input = {"party1", "party2", "party3"},
                exp = {"party1", "party2", "party3"},
            },
            {
                name = "master",
                input = {"party1", "party2", "party3"},
                exp = {"party2"},
            },
            {
                name = "master",
                input = {"party1", "party3"},
                exp = {},
            },
            {
                name = "group",
                input = {"party1", "party2"},
                exp = {"party1", "party2"},
            },
        }

        for i, test in ipairs(scenarios) do
            _G._currentTestScenario = test.name
            local ok, result = pcall(fn, test.input)

            _G["test" .. i] = "Сценарий '" .. test.name .. "' | Получено: {" .. table.concat(result or {}, ", ") .. "} | Ожидалось: {" .. table.concat(test.exp, ", ") .. "}"

            if not ok then
                return fail("Тест " .. i .. ": ошибка вызова: " .. tostring(result))
            end

            if type(result) ~= "table" then
                return fail("Тест " .. i .. ": функция должна вернуть таблицу")
            end

            if #result ~= #test.exp then
                return fail("Тест " .. i .. " не пройден: не совпадает длина массива")
            end

            for j = 1, #result do
                if result[j] ~= test.exp[j] then
                    return fail("Тест " .. i .. " не пройден: элемент " .. j .. " не совпадает")
                end
            end
        end

        _G._currentTestScenario = nil
        return true
    end,
}

ns_llua['lua'][131] = {
type = "info",
title = "Гильдия",
helpModules = {113, 65},
content = [=[
<h>Гильдия</h>
<t>WoW API позволяет получать информацию о гильдии игрока.</t>
<h>GetGuildInfo</h>
<code>
/run local guildName, guildRankName = GetGuildInfo("player"); print(guildName or "Без гильдии", guildRankName or "")
</code>
<t>Если игрок не состоит в гильдии, <k>guildName</k> может быть <k>nil</k>.</t>
<h>Количество участников гильдии</h>
<code>
/run local total, online = GetNumGuildMembers(); print(total, online)
</code>
<t>Первое значение — всего участников, второе — онлайн.</t>
<w>Важно:</w> данные гильдии могут быть доступны не мгновенно. Иногда они подгружаются после открытия окна гильдии или после запроса ростера.
<h>GetGuildRosterInfo</h>
<code>
/run local name, rank, rankIndex, level = GetGuildRosterInfo(1); print(name, rank, rankIndex, level)
</code>
<t>Функция возвращает данные участника гильдии по индексу.</t>
<h>Безопасный пример</h>
<code>
/run local guildName = GetGuildInfo("player"); if guildName then print("Гильдия:", guildName) else print("Игрок без гильдии") end
</code>
<h>Таблица участников</h>
<code>
/run guildOnline = {}; local total, online = GetNumGuildMembers(); if online then for i = 1, online do local name = GetGuildRosterInfo(i); if name then table.insert(guildOnline, name) end end end; print("Онлайн:", #guildOnline)
</code>
<w>Примечание:</w> если ростер гильдии ещё не загружен, значения могут быть <k>nil</k>. Позже, в модуле событий, мы научимся обновлять такие данные по событию.
<h>Безопасные значения по умолчанию</h>
<code>
/run local total = GetNumGuildMembers() or 0; local online = select(2, GetNumGuildMembers()) or 0; print("Всего:", total, "Онлайн:", online)
</code>
]=],
}

ns_llua['lua'][132] = {
type = "vartest",
title = "Тест 131-1: имя гильдии",
helpModules = {131, 65},
tasks = {
{
var = "guildName",
desc = 'Создай глобальную переменную guildName = GetGuildInfo("player") or "Без гильдии"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
},
}

ns_llua['lua'][133] = {
type = "vartest",
title = "Тест 131-2: количество участников гильдии",
helpModules = {131, 65},
tasks = {
{
var = "guildTotal",
desc = 'Создай глобальную переменную guildTotal = GetNumGuildMembers() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "guildOnline",
desc = 'Создай глобальную переменную guildOnline = select(2, GetNumGuildMembers()) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][134] = {
type = "commenttest",
title = "Тест 131-3: функция GetGuildNameSafe",
helpModules = {131, 45, 65},
preloadVars = {
{var = "GetGuildNameSafe", desc = "GetGuildNameSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 131-3: функция GetGuildNameSafe</h>
<t>Создай глобальную функцию <k>GetGuildNameSafe()</k>.</t>
<t>Функция должна вернуть имя гильдии игрока через:</t>
<code>
GetGuildInfo("player")
</code>
<t>Если имя не является непустой строкой, функция должна вернуть строку:</t>
<s>"Без гильдии"</s>
<t>Используй:</t>
<c>GetGuildInfo</c>
<c>type</c>
<c>return</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetGuildNameSafe()
]=],
requireKeywords = {
"GetGuildNameSafe",
"function",
"GetGuildInfo",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetGuildNameSafe) ~= "function" then
_G.checkError = "GetGuildNameSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetGuildNameSafe)
if not ok then
_G.checkError = "Ошибка вызова GetGuildNameSafe: " .. tostring(result)
return false
end
if type(result) ~= "string" or result == "" then
_G.checkError = "Функция должна вернуть непустую строку"
return false
end
return true
end,
}

ns_llua['lua'][135] = {
type = "commenttest",
title = "Тест 131-4: функция GetGuildMemberCountSafe",
helpModules = {131, 45, 65},
preloadVars = {
{var = "GetGuildMemberCountSafe", desc = "GetGuildMemberCountSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 131-4: функция GetGuildMemberCountSafe</h>
<t>Создай глобальную функцию <k>GetGuildMemberCountSafe()</k>.</t>
<t>Функция должна вернуть общее количество участников гильдии через:</t>
<code>
GetNumGuildMembers()
</code>
<t>Если значение не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetGuildMemberCountSafe()
]=],
requireKeywords = {
"GetGuildMemberCountSafe",
"function",
"GetNumGuildMembers",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetGuildMemberCountSafe) ~= "function" then
_G.checkError = "GetGuildMemberCountSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetGuildMemberCountSafe)
if not ok then
_G.checkError = "Ошибка вызова GetGuildMemberCountSafe: " .. tostring(result)
return false
end
if type(result) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if result < 0 then
_G.checkError = "Количество участников гильдии не может быть отрицательным"
return false
end
return true
end,
}

ns_llua['lua'][136] = {
type = "commenttest",
title = "Тест 131-5: функция GetGuildOnlineCountSafe",
helpModules = {131, 45, 65},
preloadVars = {
{var = "GetGuildOnlineCountSafe", desc = "GetGuildOnlineCountSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 131-5: функция GetGuildOnlineCountSafe</h>
<t>Создай глобальную функцию <k>GetGuildOnlineCountSafe()</k>.</t>
<t>Функция должна вернуть количество участников гильдии онлайн.</t>
<t>Используй:</t>
<code>
local total, online = GetNumGuildMembers()
</code>
<t>Если <k>online</k> не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetGuildOnlineCountSafe()
]=],
requireKeywords = {
"GetGuildOnlineCountSafe",
"function",
"GetNumGuildMembers",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetGuildOnlineCountSafe) ~= "function" then
_G.checkError = "GetGuildOnlineCountSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetGuildOnlineCountSafe)
if not ok then
_G.checkError = "Ошибка вызова GetGuildOnlineCountSafe: " .. tostring(result)
return false
end
if type(result) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if result < 0 then
_G.checkError = "Количество участников онлайн не может быть отрицательным"
return false
end
return true
end,
}

ns_llua['lua'][137] = {
type = "info",
title = "Координаты игрока",
helpModules = {65, 71, 14},
content = [=[
<h>Координаты игрока</h>
<t>Функция <k>GetPlayerMapPosition</k> возвращает координаты юнита на текущей карте.</t>
<code>
/run local x, y = GetPlayerMapPosition("player"); print(x, y)
</code>
<t>Координаты возвращаются как доли от 0 до 1.</t>
<t>Чтобы получить привычные проценты, их нужно умножить на 100.</t>
<code>
/run local x, y = GetPlayerMapPosition("player"); if x and y then print(string.format("X: %.1f, Y: %.1f", x * 100, y * 100)) end
</code>
<h>SetMapToCurrentZone</h>
<t>Иногда координаты могут быть <n>0, 0</n>, если текущая карта не соответствует зоне игрока.</t>
<code>
/run SetMapToCurrentZone(); local x, y = GetPlayerMapPosition("player"); if x and y then print(string.format("X: %.1f, Y: %.1f", x * 100, y * 100)) end
</code>
<w>Важно:</w> в некоторых местах, например в подземельях или на специальных картах, координаты могут быть недоступны.
<h>Безопасный шаблон</h>
<code>
/run local x, y = GetPlayerMapPosition("player"); x = x or 0; y = y or 0; print(string.format("X: %.1f, Y: %.1f", x * 100, y * 100))
</code>
<h>Формат вывода</h>
<t>В <k>string.format</k> метка <k>%.1f</k> означает число с одним знаком после запятой.</t>
<code>
print(string.format("%.1f", 12.345)) -- 12.3
print(string.format("%.2f", 12.345)) -- 12.35
</code>
]=],
}

ns_llua['lua'][138] = {
type = "vartest",
title = "Тест 137-1: сырые координаты игрока",
helpModules = {137, 65},
tasks = {
{
var = "mapX",
desc = 'Создай глобальную переменную mapX = (GetPlayerMapPosition("player")) or 0',
check = function(value)
return type(value) == "number" and value >= 0 and value <= 1
end,
},
{
var = "mapY",
desc = 'Создай глобальную переменную mapY = select(2, GetPlayerMapPosition("player")) or 0',
check = function(value)
return type(value) == "number" and value >= 0 and value <= 1
end,
},
},
}

ns_llua['lua'][139] = {
type = "vartest",
title = "Тест 137-2: координаты в процентах",
helpModules = {137, 10, 14},
tasks = {
{
var = "mapXPercent",
desc = 'Создай глобальную переменную mapXPercent = math.floor(((GetPlayerMapPosition("player")) or 0) * 100)',
check = function(value)
return type(value) == "number" and value >= 0 and value <= 100
end,
},
{
var = "mapYPercent",
desc = 'Создай глобальную переменную mapYPercent = math.floor((select(2, GetPlayerMapPosition("player")) or 0) * 100)',
check = function(value)
return type(value) == "number" and value >= 0 and value <= 100
end,
},
},
}

ns_llua['lua'][140] = {
type = "commenttest",
title = "Тест 137-3: функция GetPlayerCoordinatesRaw",
helpModules = {137, 45, 65},
preloadVars = {
{var = "GetPlayerCoordinatesRaw", desc = "GetPlayerCoordinatesRaw очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 137-3: функция GetPlayerCoordinatesRaw</h>
<t>Создай глобальную функцию <k>GetPlayerCoordinatesRaw()</k>.</t>
<t>Функция должна вернуть два значения:</t>
<c>1</c> — координату X игрока через <k>GetPlayerMapPosition("player")</k>.
<c>2</c> — координату Y игрока через <k>GetPlayerMapPosition("player")</k>.
<t>Если значение равно <k>nil</k>, используй <n>0</n>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetPlayerCoordinatesRaw()
]=],
requireKeywords = {
"GetPlayerCoordinatesRaw",
"function",
"GetPlayerMapPosition",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetPlayerCoordinatesRaw) ~= "function" then
_G.checkError = "GetPlayerCoordinatesRaw не является глобальной функцией"
return false
end
local ok, x, y = pcall(_G.GetPlayerCoordinatesRaw)
if not ok then
_G.checkError = "Ошибка вызова GetPlayerCoordinatesRaw: " .. tostring(x)
return false
end
if type(x) ~= "number" or type(y) ~= "number" then
_G.checkError = "Функция должна вернуть два числа"
return false
end
if x < 0 or x > 1 then
_G.checkError = "Координата X должна быть от 0 до 1"
return false
end
if y < 0 or y > 1 then
_G.checkError = "Координата Y должна быть от 0 до 1"
return false
end
return true
end,
}

ns_llua['lua'][141] = {
type = "commenttest",
title = "Тест 137-4: функция GetPlayerCoordinatesPercent",
helpModules = {137, 45, 10, 14},
preloadVars = {
{var = "GetPlayerCoordinatesPercent", desc = "GetPlayerCoordinatesPercent очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 137-4: функция GetPlayerCoordinatesPercent</h>
<t>Создай глобальную функцию <k>GetPlayerCoordinatesPercent()</k>.</t>
<t>Функция должна вернуть два значения:</t>
<c>1</c> — координату X игрока в процентах от 0 до 100.
<c>2</c> — координату Y игрока в процентах от 0 до 100.
<t>Используй:</t>
<c>GetPlayerMapPosition("player")</c>
<c>or 0</c>
<c>math.floor</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetPlayerCoordinatesPercent()
]=],
requireKeywords = {
"GetPlayerCoordinatesPercent",
"function",
"GetPlayerMapPosition",
"math.floor",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetPlayerCoordinatesPercent) ~= "function" then
_G.checkError = "GetPlayerCoordinatesPercent не является глобальной функцией"
return false
end
local ok, xPercent, yPercent = pcall(_G.GetPlayerCoordinatesPercent)
if not ok then
_G.checkError = "Ошибка вызова GetPlayerCoordinatesPercent: " .. tostring(xPercent)
return false
end
if type(xPercent) ~= "number" or type(yPercent) ~= "number" then
_G.checkError = "Функция должна вернуть два числа"
return false
end
if xPercent < 0 or xPercent > 100 then
_G.checkError = "Координата X в процентах должна быть от 0 до 100"
return false
end
if yPercent < 0 or yPercent > 100 then
_G.checkError = "Координата Y в процентах должна быть от 0 до 100"
return false
end
return true
end,
}

ns_llua['lua'][142] = {
type = "commenttest",
title = "Тест 137-5: функция GetCoordinateText",
helpModules = {137, 45, 14, 7},
preloadVars = {
{var = "GetCoordinateText", desc = "GetCoordinateText очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 137-5: функция GetCoordinateText</h>
<t>Создай глобальную функцию <k>GetCoordinateText()</k>.</t>
<t>Функция должна вернуть строку с координатами игрока в процентах.</t>
<t>Формат строки:</t>
<s>"X: 12.3, Y: 45.6"</s>
<t>Используй:</t>
<c>GetPlayerMapPosition("player")</c>
<c>or 0</c>
<c>string.format</c>
<c>%.1f</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetCoordinateText()
]=],
requireKeywords = {
"GetCoordinateText",
"function",
"GetPlayerMapPosition",
"string.format",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetCoordinateText) ~= "function" then
_G.checkError = "GetCoordinateText не является глобальной функцией"
return false
end
local ok, text = pcall(_G.GetCoordinateText)
if not ok then
_G.checkError = "Ошибка вызова GetCoordinateText: " .. tostring(text)
return false
end
if type(text) ~= "string" or text == "" then
_G.checkError = "Функция должна вернуть строку"
return false
end
if not text:find("X: ", 1, true) then
_G.checkError = "Строка должна начинаться с 'X: '"
return false
end
if not text:find(", Y: ", 1, true) then
_G.checkError = "Строка должна содержать ', Y: '"
return false
end
return true
end,
}

ns_llua['lua'][143] = {
type = "info",
title = "Направление и зоны",
helpModules = {137, 10, 14},
content = [=[
<h>Направление и зоны</h>
<t>Кроме координат, можно получить направление взгляда игрока и название зоны.</t>
<h>GetPlayerFacing</h>
<code>
/run print(GetPlayerFacing())
</code>
<t>Функция возвращает направление в радианах.</t>
<t>Чтобы перевести радианы в градусы, используй формулу:</t>
<code>
градусы = радианы * 180 / math.pi
</code>
<h>Пример перевода</h>
<code>
/run local facing = GetPlayerFacing() or 0; local degrees = math.floor(facing * 180 / math.pi + 0.5); print(degrees)
</code>
<t>Результат будет примерно от 0 до 360.</t>
<h>Названия зон</h>
<code>
/run print(GetZoneText())
/run print(GetRealZoneText())
/run print(GetMinimapZoneText())
/run print(GetSubZoneText())
</code>
<t>Разница:</t>
<c>GetZoneText</c> — основная зона.
<c>GetRealZoneText</c> — реальная зона, часто используется для континентов и крупных областей.
<c>GetMinimapZoneText</c> — текст миникарты.
<c>GetSubZoneText</c> — подзона, например конкретная улица, пещера или здание.
<h>Пример отчёта</h>
<code>
/run local zone = GetZoneText() or "Неизвестно"; local sub = GetSubZoneText() or ""; print(string.format("Зона: %s, подзона: %s", zone, sub))
</code>
<h>Безопасный шаблон</h>
<code>
/run local facing = GetPlayerFacing() or 0; if facing >= 0 then print("Направление доступно") else print("Направление недоступно") end
</code>
]=],
}

ns_llua['lua'][144] = {
type = "vartest",
title = "Тест 143-1: направление игрока",
helpModules = {143, 65, 10},
tasks = {
{
var = "playerFacing",
desc = 'Создай глобальную переменную playerFacing = GetPlayerFacing() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerFacingDegrees",
desc = 'Создай глобальную переменную playerFacingDegrees = math.floor((GetPlayerFacing() or 0) * 180 / math.pi + 0.5)',
check = function(value)
return type(value) == "number" and value >= 0 and value <= 360
end,
},
},
}

ns_llua['lua'][145] = {
type = "vartest",
title = "Тест 143-2: зоны игрока",
helpModules = {143, 65},
tasks = {
{
var = "zoneText",
desc = 'Создай глобальную переменную zoneText = GetZoneText() or "Неизвестно"',
check = function(value)
return type(value) == "string"
end,
},
{
var = "minimapZoneText",
desc = 'Создай глобальную переменную minimapZoneText = GetMinimapZoneText() or ""',
check = function(value)
return type(value) == "string"
end,
},
},
}

ns_llua['lua'][146] = {
type = "commenttest",
title = "Тест 143-3: функция GetFacingDegrees",
helpModules = {143, 45, 10},
preloadVars = {
{var = "GetFacingDegrees", desc = "GetFacingDegrees очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 143-3: функция GetFacingDegrees</h>
<t>Создай глобальную функцию <k>GetFacingDegrees()</k>.</t>
<t>Функция должна вернуть направление игрока в градусах.</t>
<t>Используй:</t>
<c>GetPlayerFacing()</c>
<c>or 0</c>
<c>math.floor</c>
<c>math.pi</c>
<t>Если направление недоступно, функция должна вернуть <n>0</n>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetFacingDegrees()
]=],
requireKeywords = {
"GetFacingDegrees",
"function",
"GetPlayerFacing",
"math.floor",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetFacingDegrees) ~= "function" then
_G.checkError = "GetFacingDegrees не является глобальной функцией"
return false
end
local ok, degrees = pcall(_G.GetFacingDegrees)
if not ok then
_G.checkError = "Ошибка вызова GetFacingDegrees: " .. tostring(degrees)
return false
end
if type(degrees) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if degrees < 0 or degrees > 360 then
_G.checkError = "Направление в градусах должно быть от 0 до 360"
return false
end
return true
end,
}

ns_llua['lua'][147] = {
type = "commenttest",
title = "Тест 143-4: функция GetZoneReport",
helpModules = {143, 45, 7},
preloadVars = {
{var = "GetZoneReport", desc = "GetZoneReport очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 143-4: функция GetZoneReport</h>
<t>Создай глобальную функцию <k>GetZoneReport()</k>.</t>
<t>Функция должна вернуть строку:</t>
<s>"Зона: название"</s>
<t>Если <k>GetZoneText()</k> вернул <k>nil</k>, используй строку:</t>
<s>"Неизвестно"</s>
<t>Используй:</t>
<c>GetZoneText</c>
<c>or</c>
<c>конкатенацию</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetZoneReport()
]=],
requireKeywords = {
"GetZoneReport",
"function",
"GetZoneText",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetZoneReport) ~= "function" then
_G.checkError = "GetZoneReport не является глобальной функцией"
return false
end
local ok, text = pcall(_G.GetZoneReport)
if not ok then
_G.checkError = "Ошибка вызова GetZoneReport: " .. tostring(text)
return false
end
if type(text) ~= "string" or text == "" then
_G.checkError = "Функция должна вернуть строку"
return false
end
if not text:find("Зона: ", 1, true) then
_G.checkError = "Строка должна начинаться с 'Зона: '"
return false
end
return true
end,
}

ns_llua['lua'][148] = {
type = "commenttest",
title = "Тест 143-5: функция GetCardinalDirection",
helpModules = {143, 45, 17, 19},
preloadVars = {
{var = "GetCardinalDirection", desc = "GetCardinalDirection очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 143-5: функция GetCardinalDirection</h>
<t>Создай глобальную функцию <k>GetCardinalDirection(degrees)</k>.</t>
<t>Функция должна вернуть сторону света по градусам.</t>
<t>Правила:</t>
<c>0-44</c> — <s>"Север"</s>
<c>45-134</c> — <s>"Восток"</s>
<c>135-224</c> — <s>"Юг"</s>
<c>225-314</c> — <s>"Запад"</s>
<c>315-359</c> — <s>"Север"</s>
<t>Если <k>degrees</k> не число, меньше 0 или больше либо равно 360, функция должна вернуть:</t>
<s>"Неизвестно"</s>
<t>Используй:</t>
<c>type</c>
<c>if</c>
<c>elseif</c>
<c>else</c>
<c>return</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetCardinalDirection(degrees)
]=],
requireKeywords = {
"GetCardinalDirection",
"function",
"type",
"if",
"then",
"elseif",
"else",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetCardinalDirection) ~= "function" then
_G.checkError = "GetCardinalDirection не является глобальной функцией"
return false
end
local tests = {
{input = 0, expected = "Север"},
{input = 44, expected = "Север"},
{input = 45, expected = "Восток"},
{input = 90, expected = "Восток"},
{input = 134, expected = "Восток"},
{input = 135, expected = "Юг"},
{input = 180, expected = "Юг"},
{input = 224, expected = "Юг"},
{input = 225, expected = "Запад"},
{input = 270, expected = "Запад"},
{input = 314, expected = "Запад"},
{input = 315, expected = "Север"},
{input = 359, expected = "Север"},
{input = -1, expected = "Неизвестно"},
{input = 360, expected = "Неизвестно"},
{input = "bad", expected = "Неизвестно"},
}
for i, test in ipairs(tests) do
local ok, result = pcall(_G.GetCardinalDirection, test.input)
if not ok or result ~= test.expected then
_G.checkError = "Тест " .. i .. " функции GetCardinalDirection не пройден"
return false
end
end
return true
end,
}

ns_llua['lua'][149] = {
type = "info",
title = "Скорость и перемещение",
helpModules = {143, 65},
content = [=[
<h>Скорость и перемещение</h>
<t>WoW API позволяет получить скорость игрока и проверить, находится ли он верхом, летит или плывёт.</t>
<h>GetPlayerSpeed</h>
<code>
/run local runSpeed, flightSpeed = GetPlayerSpeed(); print(runSpeed, flightSpeed)
</code>
<t>Функция возвращает скорость бега и скорость полёта.</t>
<w>Примечание:</w> значения могут отличаться в зависимости от версии клиента и настроек. Их удобно смотреть через <k>/dump</k>.
<code>
/dump GetPlayerSpeed()
</code>
<h>GetUnitSpeed</h>
<t>Если функция доступна, можно получить скорость конкретного юнита.</t>
<code>
/run print(GetUnitSpeed("player"))
</code>
<h>Состояния движения</h>
<code>
/run print(IsMounted())
/run print(IsFlying())
/run print(IsSwimming())
/run print(IsIndoors())
/run print(IsOutdoors())
</code>
<t>Как и многие функции WoW 3.3.5, они могут возвращать <k>1</k> или <k>nil</k>.</t>
<h>Пример условия</h>
<code>
/run if IsMounted() then print("Верхом") else print("Пешком") end
</code>
<h>Приведение к boolean</h>
<code>
/run local mounted = not not IsMounted(); print(mounted, type(mounted))
</code>
<h>Мини-отчёт</h>
<code>
/run local state = "Пешком"; if IsFlying() then state = "Летит" elseif IsMounted() then state = "Верхом" elseif IsSwimming() then state = "Плывёт" end; print(state)
</code>
<h>Безопасный шаблон скорости</h>
<code>
/run local speed = 0; if GetPlayerSpeed then speed = GetPlayerSpeed() or 0 end; print("Скорость:", speed)
</code>
]=],
}

ns_llua['lua'][150] = {
type = "vartest",
title = "Тест 149-1: состояния движения",
helpModules = {149, 15},
tasks = {
{
var = "isMounted",
desc = 'Создай глобальную переменную isMounted = not not IsMounted()',
check = function(value)
return type(value) == "boolean"
end,
},
{
var = "isFlying",
desc = 'Создай глобальную переменную isFlying = not not IsFlying()',
check = function(value)
return type(value) == "boolean"
end,
},
{
var = "isSwimming",
desc = 'Создай глобальную переменную isSwimming = not not IsSwimming()',
check = function(value)
return type(value) == "boolean"
end,
},
},
}

ns_llua['lua'][151] = {
type = "vartest",
title = "Тест 149-2: скорость игрока",
helpModules = {149, 65},
tasks = {
{
var = "runSpeed",
desc = 'Создай глобальную переменную runSpeed: если GetPlayerSpeed существует, используй её результат, иначе 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "flightSpeed",
desc = 'Создай глобальную переменную flightSpeed: если GetPlayerSpeed существует, используй второй результат через select(2, ...), иначе 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][152] = {
type = "commenttest",
title = "Тест 149-3: функция GetMovementState",
helpModules = {149, 45, 17, 19},
preloadVars = {
{var = "GetMovementState", desc = "GetMovementState очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 149-3: функция GetMovementState</h>
<t>Создай глобальную функцию <k>GetMovementState()</k>.</t>
<t>Функция должна вернуть одно из значений:</t>
<c>"flying"</c> — если <k>IsFlying()</k> истинно.
<c>"mounted"</c> — если игрок не летит, но <k>IsMounted()</k> истинно.
<c>"swimming"</c> — если игрок не летит, не верхом, но <k>IsSwimming()</k> истинно.
<c>"normal"</c> — во всех остальных случаях.
<t>Используй:</t>
<c>IsFlying</c>
<c>IsMounted</c>
<c>IsSwimming</c>
<c>if / elseif / else</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetMovementState()
]=],
requireKeywords = {
"GetMovementState",
"function",
"IsFlying",
"IsMounted",
"IsSwimming",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetMovementState) ~= "function" then
_G.checkError = "GetMovementState не является глобальной функцией"
return false
end
local ok, state = pcall(_G.GetMovementState)
if not ok then
_G.checkError = "Ошибка вызова GetMovementState: " .. tostring(state)
return false
end
local valid = {
flying = true,
mounted = true,
swimming = true,
normal = true,
}
if type(state) ~= "string" or not valid[state] then
_G.checkError = "Функция должна вернуть flying, mounted, swimming или normal"
return false
end
return true
end,
}

ns_llua['lua'][153] = {
type = "commenttest",
title = "Тест 149-4: функция GetSpeedReport",
helpModules = {149, 45, 7, 65},
preloadVars = {
{var = "GetSpeedReport", desc = "GetSpeedReport очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 149-4: функция GetSpeedReport</h>
<t>Создай глобальную функцию <k>GetSpeedReport()</k>.</t>
<t>Функция должна вернуть строку:</t>
<s>"Скорость: значение"</s>
<t>Если функция <k>GetPlayerSpeed</k> недоступна, используй значение <n>0</n>.</t>
<t>Используй:</t>
<c>GetPlayerSpeed</c>
<c>tostring</c>
<c>конкатенацию</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetSpeedReport()
]=],
requireKeywords = {
"GetSpeedReport",
"function",
"GetPlayerSpeed",
"tostring",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetSpeedReport) ~= "function" then
_G.checkError = "GetSpeedReport не является глобальной функцией"
return false
end
local ok, text = pcall(_G.GetSpeedReport)
if not ok then
_G.checkError = "Ошибка вызова GetSpeedReport: " .. tostring(text)
return false
end
if type(text) ~= "string" or text == "" then
_G.checkError = "Функция должна вернуть строку"
return false
end
if not text:find("Скорость: ", 1, true) then
_G.checkError = "Строка должна начинаться с 'Скорость: '"
return false
end
return true
end,
}

ns_llua['lua'][154] = {
type = "commenttest",
title = "Тест 149-5: функция IsMountedOrFlying",
helpModules = {149, 45, 21},
preloadVars = {
{var = "IsMountedOrFlying", desc = "IsMountedOrFlying очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 149-5: функция IsMountedOrFlying</h>
<t>Создай глобальную функцию <k>IsMountedOrFlying()</k>.</t>
<t>Функция должна вернуть <k>true</k>, если игрок верхом или летит.</t>
<t>Иначе функция должна вернуть <k>false</k>.</t>
<t>Используй:</t>
<c>IsMounted()</c>
<c>IsFlying()</c>
<c>or</c>
<c>and true or false</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию IsMountedOrFlying()
]=],
requireKeywords = {
"IsMountedOrFlying",
"function",
"IsMounted",
"IsFlying",
"and",
"or",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.IsMountedOrFlying) ~= "function" then
_G.checkError = "IsMountedOrFlying не является глобальной функцией"
return false
end
local ok, result = pcall(_G.IsMountedOrFlying)
if not ok then
_G.checkError = "Ошибка вызова IsMountedOrFlying: " .. tostring(result)
return false
end
if type(result) ~= "boolean" then
_G.checkError = "Функция должна вернуть boolean"
return false
end
return true
end,
}

ns_llua['lua'][155] = {
type = "info",
title = "Время, FPS и пинг",
helpModules = {65, 10, 14},
content = [=[
<h>Время, FPS и пинг</h>
<t>Эти функции полезны для таймеров, измерений и диагностики.</t>
<h>GetTime</h>
<code>
/run print(GetTime())
</code>
<t>Возвращает время в секундах. Обычно это время с момента загрузки интерфейса.</t>
<h>Целые секунды</h>
<code>
/run print(math.floor(GetTime()))
</code>
<h>Минуты и секунды</h>
<code>
/run local t = math.floor(GetTime()); print(string.format("Прошло %d мин %d сек", math.floor(t / 60), t % 60))
</code>
<h>GetGameTime</h>
<code>
/run local hour, minute = GetGameTime(); print(hour, minute)
</code>
<t>Функция возвращает игровое или серверное время в формате часы и минуты.</t>
<h>GetFramerate</h>
<code>
/run print(math.floor(GetFramerate()))
</code>
<t>Возвращает текущий FPS.</t>
<h>GetNetStats</h>
<t>Функция возвращает статистику сети. Удобнее всего сначала посмотреть её через <k>/dump</k>.</t>
<code>
/dump GetNetStats()
</code>
<t>Пример получения домашнего пинга:</t>
<code>
/run local _, _, latencyHome = GetNetStats(); print(latencyHome or 0)
</code>
<w>Примечание:</w> порядок возвращаемых значений может зависеть от версии клиента, поэтому при сомнениях используй <k>/dump</k>.
<h>Безопасный шаблон</h>
<code>
/run local fps = GetFramerate() or 0; print(string.format("FPS: %d", math.floor(fps)))
</code>
]=],
}

ns_llua['lua'][156] = {
type = "vartest",
title = "Тест 155-1: время сессии",
helpModules = {155, 65, 10},
tasks = {
{
var = "gameTimeSeconds",
desc = 'Создай глобальную переменную gameTimeSeconds = GetTime() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "gameTimeMinutes",
desc = 'Создай глобальную переменную gameTimeMinutes = math.floor((GetTime() or 0) / 60)',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][157] = {
type = "vartest",
title = "Тест 155-2: игровое время",
helpModules = {155, 65},
tasks = {
{
var = "gameHour",
desc = 'Создай глобальную переменную gameHour = GetGameTime() or 0',
check = function(value)
return type(value) == "number" and value >= 0 and value <= 23
end,
},
{
var = "gameMinute",
desc = 'Создай глобальную переменную gameMinute = select(2, GetGameTime()) or 0',
check = function(value)
return type(value) == "number" and value >= 0 and value <= 59
end,
},
},
}

ns_llua['lua'][158] = {
type = "commenttest",
title = "Тест 155-3: функция GetSessionTimeText",
helpModules = {155, 45, 14, 10},
preloadVars = {
{var = "GetSessionTimeText", desc = "GetSessionTimeText очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 155-3: функция GetSessionTimeText</h>
<t>Создай глобальную функцию <k>GetSessionTimeText()</k>.</t>
<t>Функция должна вернуть строку с временем сессии.</t>
<t>Формат строки:</t>
<s>"Минут: X, Секунд: Y"</s>
<t>Используй:</t>
<c>GetTime()</c>
<c>math.floor</c>
<c>остаток от деления %</c>
<c>string.format</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetSessionTimeText()
]=],
requireKeywords = {
"GetSessionTimeText",
"function",
"GetTime",
"math.floor",
"string.format",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetSessionTimeText) ~= "function" then
_G.checkError = "GetSessionTimeText не является глобальной функцией"
return false
end
local ok, text = pcall(_G.GetSessionTimeText)
if not ok then
_G.checkError = "Ошибка вызова GetSessionTimeText: " .. tostring(text)
return false
end
if type(text) ~= "string" or text == "" then
_G.checkError = "Функция должна вернуть строку"
return false
end
if not text:find("Минут: ", 1, true) then
_G.checkError = "Строка должна содержать 'Минут: '"
return false
end
if not text:find(", Секунд: ", 1, true) then
_G.checkError = "Строка должна содержать ', Секунд: '"
return false
end
return true
end,
}

ns_llua['lua'][159] = {
type = "commenttest",
title = "Тест 155-4: функция GetFramerateSafe",
helpModules = {155, 45, 65},
preloadVars = {
{var = "GetFramerateSafe", desc = "GetFramerateSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 155-4: функция GetFramerateSafe</h>
<t>Создай глобальную функцию <k>GetFramerateSafe()</k>.</t>
<t>Функция должна вернуть FPS как число.</t>
<t>Используй:</t>
<c>GetFramerate()</c>
<c>or 0</c>
<t>Если FPS получить нельзя, функция должна вернуть <n>0</n>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetFramerateSafe()
]=],
requireKeywords = {
"GetFramerateSafe",
"function",
"GetFramerate",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetFramerateSafe) ~= "function" then
_G.checkError = "GetFramerateSafe не является глобальной функцией"
return false
end
local ok, fps = pcall(_G.GetFramerateSafe)
if not ok then
_G.checkError = "Ошибка вызова GetFramerateSafe: " .. tostring(fps)
return false
end
if type(fps) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if fps < 0 then
_G.checkError = "FPS не может быть отрицательным"
return false
end
return true
end,
}

ns_llua['lua'][160] = {
type = "commenttest",
title = "Тест 155-5: функция GetLatencySafe",
helpModules = {155, 45, 65},
preloadVars = {
{var = "GetLatencySafe", desc = "GetLatencySafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 155-5: функция GetLatencySafe</h>
<t>Создай глобальную функцию <k>GetLatencySafe()</k>.</t>
<t>Функция должна вернуть пинг как число.</t>
<t>Используй:</t>
<c>GetNetStats()</c>
<c>select(3, ...)</c>
<c>or 0</c>
<t>Если пинг получить нельзя, функция должна вернуть <n>0</n>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetLatencySafe()
]=],
requireKeywords = {
"GetLatencySafe",
"function",
"GetNetStats",
"select",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetLatencySafe) ~= "function" then
_G.checkError = "GetLatencySafe не является глобальной функцией"
return false
end
local ok, latency = pcall(_G.GetLatencySafe)
if not ok then
_G.checkError = "Ошибка вызова GetLatencySafe: " .. tostring(latency)
return false
end
if type(latency) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if latency < 0 then
_G.checkError = "Пинг не может быть отрицательным"
return false
end
return true
end,
}

ns_llua['lua'][161] = {
type = "info",
title = "Деньги и опыт",
helpModules = {65, 10, 14},
content = [=[
<h>Деньги и опыт</h>
<t>Деньги в WoW хранятся в меди. 100 меди — 1 серебро. 100 серебра — 1 золото.</t>
<h>GetMoney</h>
<code>
/run print(GetMoney())
</code>
<t>Функция возвращает общее количество меди.</t>
<h>Ручное форматирование</h>
<code>
/run local copper = GetMoney() or 0; local gold = math.floor(copper / 10000); local silver = math.floor((copper % 10000) / 100); local cop = copper % 100; print(string.format("%dз %dс %dм", gold, silver, cop))
</code>
<t>Здесь:</t>
<c>copper / 10000</c> — золото.
<c>(copper % 10000) / 100</c> — серебро.
<c>copper % 100</c> — медь.
<h>GetCoinTextureString</h>
<t>Готовая функция для красивого вывода денег.</t>
<code>
/run print(GetCoinTextureString(GetMoney()))
</code>
<h>Опыт</h>
<code>
/run local xp = UnitXP("player"); local xpMax = UnitXPMax("player"); print(xp, xpMax)
</code>
<h>Процент опыта</h>
<code>
/run local xp = UnitXP("player") or 0; local xpMax = UnitXPMax("player") or 0; if xpMax > 0 then print(string.format("XP: %d%%", math.floor(xp / xpMax * 100))) else print("XP: 0%") end
</code>
<w>Важно:</w> на максимальном уровне <k>xpMax</k> может быть <n>0</n>, поэтому деление нужно проверять.
<h>Отдых</h>
<code>
/run print(GetXPExhaustion())
</code>
<t>Функция возвращает количество накопленного отдыха, если оно доступно.</t>
]=],
}

ns_llua['lua'][162] = {
type = "vartest",
title = "Тест 161-1: деньги игрока",
helpModules = {161, 65, 10},
tasks = {
{
var = "playerMoney",
desc = 'Создай глобальную переменную playerMoney = GetMoney() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerGold",
desc = 'Создай глобальную переменную playerGold = math.floor((GetMoney() or 0) / 10000)',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][163] = {
type = "vartest",
title = "Тест 161-2: опыт игрока",
helpModules = {161, 65},
tasks = {
{
var = "playerXP",
desc = 'Создай глобальную переменную playerXP = UnitXP("player") or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerXPMax",
desc = 'Создай глобальную переменную playerXPMax = UnitXPMax("player") or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][164] = {
type = "commenttest",
title = "Тест: функция GetMoneyParts",
helpModules = {161, 45, 10},
preloadVars = {
{var = "GetMoneyParts", desc = "GetMoneyParts очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 161-3: функция GetMoneyParts</h>
<t>Создай глобальную функцию <k>GetMoneyParts()</k>.</t>
<t>Функция должна вернуть три значения:</t>
<c>1</c> — золото.
<c>2</c> — серебро.
<c>3</c> — медь.
<t>Используй:</t>
<c>GetMoney()</c>
<c>or 0</c>
<c>math.floor</c>
<c>остаток от деления %</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetMoneyParts()
]=],
requireKeywords = {
"GetMoneyParts",
"function",
"GetMoney",
"math.floor",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetMoneyParts) ~= "function" then
_G.checkError = "GetMoneyParts не является глобальной функцией"
return false
end
local money = GetMoney() or 0
local expectedGold = math.floor(money / 10000)
local expectedSilver = math.floor((money % 10000) / 100)
local expectedCopper = money % 100
local ok, gold, silver, copper = pcall(_G.GetMoneyParts)
if not ok then
_G.checkError = "Ошибка вызова GetMoneyParts: " .. tostring(gold)
return false
end
if type(gold) ~= "number" or type(silver) ~= "number" or type(copper) ~= "number" then
_G.checkError = "Функция должна вернуть три числа"
return false
end
if gold ~= expectedGold or silver ~= expectedSilver or copper ~= expectedCopper then
_G.checkError = "Золото, серебро или медь посчитаны неверно"
return false
end
return true
end,
}

ns_llua['lua'][165] = {
type = "commenttest",
title = "Тест 161-4: функция GetMoneyText",
helpModules = {161, 45, 14, 10},
preloadVars = {
{var = "GetMoneyText", desc = "GetMoneyText очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 161-4: функция GetMoneyText</h>
<t>Создай глобальную функцию <k>GetMoneyText()</k>.</t>
<t>Функция должна вернуть строку с деньгами игрока.</t>
<t>Формат строки:</t>
<s>"12з 34с 56м"</s>
<t>Используй:</t>
<c>GetMoney()</c>
<c>or 0</c>
<c>math.floor</c>
<c>остаток от деления %</c>
<c>string.format</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetMoneyText()
]=],
requireKeywords = {
"GetMoneyText",
"function",
"GetMoney",
"math.floor",
"string.format",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetMoneyText) ~= "function" then
_G.checkError = "GetMoneyText не является глобальной функцией"
return false
end
local ok, text = pcall(_G.GetMoneyText)
if not ok then
_G.checkError = "Ошибка вызова GetMoneyText: " .. tostring(text)
return false
end
if type(text) ~= "string" or text == "" then
_G.checkError = "Функция должна вернуть строку"
return false
end
if not text:match("^%d+з %d+с %d+м$") then
_G.checkError = "Строка должна иметь формат 'золото з серебро с медь м'"
return false
end
return true
end,
}

ns_llua['lua'][166] = {
type = "commenttest",
title = "Тест 161-5: функция GetXPPercent",
helpModules = {161, 45, 10, 65},
preloadVars = {
{var = "GetXPPercent", desc = "GetXPPercent очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 161-5: функция GetXPPercent</h>
<t>Создай глобальную функцию <k>GetXPPercent()</k>.</t>
<t>Функция должна вернуть процент опыта игрока от 0 до 100.</t>
<t>Используй:</t>
<c>UnitXP("player")</c>
<c>UnitXPMax("player")</c>
<c>or 0</c>
<c>math.floor</c>
<t>Если максимальный опыт меньше или равен нулю, функция должна вернуть <n>0</n>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetXPPercent()
]=],
requireKeywords = {
"GetXPPercent",
"function",
"UnitXP",
"UnitXPMax",
"math.floor",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetXPPercent) ~= "function" then
_G.checkError = "GetXPPercent не является глобальной функцией"
return false
end
local ok, percent = pcall(_G.GetXPPercent)
if not ok then
_G.checkError = "Ошибка вызова GetXPPercent: " .. tostring(percent)
return false
end
if type(percent) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if percent < 0 or percent > 100 then
_G.checkError = "Процент опыта должен быть от 0 до 100"
return false
end
local xp = UnitXP("player") or 0
local xpMax = UnitXPMax("player") or 0
local expected = 0
if xpMax > 0 then
expected = math.floor(xp / xpMax * 100)
end
if math.abs(percent - expected) > 2 then
_G.checkError = "Процент опыта не совпадает с текущим опытом игрока"
return false
end
return true
end,
}

ns_llua['lua'][167] = {
type = "info",
title = "Сумки: ячейки и свободное место",
helpModules = {65, 31, 45},
content = [=[
<h>Сумки: ячейки и свободное место</h>
<t>В WoW 3.3.5 основные сумки имеют ID от 0 до 4.</t>
<c>0</c> — рюкзак.
<c>1</c> — первая дополнительная сумка.
<c>2</c> — вторая дополнительная сумка.
<c>3</c> — третья дополнительная сумка.
<c>4</c> — четвёртая дополнительная сумка.
<h>Количество ячеек</h>
<code>
/run print(GetContainerNumSlots(0))
</code>
<h>Свободные ячейки</h>
<code>
/run print(GetContainerNumFreeSlots(0))
</code>
<t>Функция может вернуть несколько значений. Первое — количество свободных ячеек.</t>
<h>Цикл по сумкам</h>
<code>
/run local total = 0; for bag = 0, 4 do total = total + (GetContainerNumSlots(bag) or 0) end; print("Всего ячеек:", total)
</code>
<h>Свободное место</h>
<code>
/run local free = 0; for bag = 0, 4 do free = free + (GetContainerNumFreeSlots(bag) or 0) end; print("Свободно:", free)
</code>
<w>Важно:</w> конструкция <k>(GetContainerNumFreeSlots(bag) or 0)</k> нужна, чтобы заменить возможный <k>nil</k> на ноль.
<h>Таблица отчёта</h>
<code>
/run bagReport = {}; for bag = 0, 4 do bagReport[bag] = { slots = GetContainerNumSlots(bag) or 0, free = GetContainerNumFreeSlots(bag) or 0 } end; print(bagReport[0].slots, bagReport[0].free)
</code>
]=],
}

ns_llua['lua'][168] = {
type = "vartest",
title = "Тест 167-1: рюкзак игрока",
helpModules = {167, 65},
tasks = {
{
var = "bagSlots0",
desc = 'Создай глобальную переменную bagSlots0 = GetContainerNumSlots(0) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "bagFree0",
desc = 'Создай глобальную переменную bagFree0 = GetContainerNumFreeSlots(0) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][169] = {
type = "vartest",
title = "Тест 167-2: таблица ID сумок",
helpModules = {167, 44},
tasks = {
{
var = "bagIDs",
desc = 'Создай глобальную таблицу bagIDs = {0, 1, 2, 3, 4}',
check = function(value)
return type(value) == "table"
and #value == 5
and value[1] == 0
and value[2] == 1
and value[3] == 2
and value[4] == 3
and value[5] == 4
end,
},
},
}

ns_llua['lua'][170] = {
type = "commenttest",
title = "Тест 167-3: функция GetBagSlotCount",
helpModules = {167, 45, 65},
preloadVars = {
{var = "GetBagSlotCount", desc = "GetBagSlotCount очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 167-3: функция GetBagSlotCount</h>
<t>Создай глобальную функцию <k>GetBagSlotCount(bag)</k>.</t>
<t>Если <k>bag</k> не является числом, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть количество ячеек в сумке через:</t>
<code>
GetContainerNumSlots(bag)
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetBagSlotCount(bag)
]=],
requireKeywords = {
"GetBagSlotCount",
"function",
"GetContainerNumSlots",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetBagSlotCount) ~= "function" then
_G.checkError = "GetBagSlotCount не является глобальной функцией"
return false
end
local ok1, backpack = pcall(_G.GetBagSlotCount, 0)
if not ok1 then
_G.checkError = "Ошибка вызова GetBagSlotCount(0): " .. tostring(backpack)
return false
end
if type(backpack) ~= "number" or backpack < 0 then
_G.checkError = "Для сумки 0 функция должна вернуть число больше или равное нулю"
return false
end
local ok2, invalidBag = pcall(_G.GetBagSlotCount, -1)
if not ok2 or invalidBag ~= 0 then
_G.checkError = "Для сумки -1 функция должна вернуть 0"
return false
end
local ok3, badBag = pcall(_G.GetBagSlotCount, "bad")
if not ok3 or badBag ~= 0 then
_G.checkError = "Для нечислового аргумента функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][171] = {
type = "commenttest",
title = "Тест 167-4: функция GetTotalBagSlots",
helpModules = {167, 45, 31, 65},
preloadVars = {
{var = "GetTotalBagSlots", desc = "GetTotalBagSlots очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 167-4: функция GetTotalBagSlots</h>
<t>Создай глобальную функцию <k>GetTotalBagSlots()</k>.</t>
<t>Функция должна вернуть общее количество ячеек во всех сумках от 0 до 4.</t>
<t>Используй цикл и:</t>
<code>
GetContainerNumSlots(bag)
</code>
<t>Если функция вернула <k>nil</k>, используй <n>0</n>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetTotalBagSlots()
]=],
requireKeywords = {
"GetTotalBagSlots",
"function",
"for",
"GetContainerNumSlots",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetTotalBagSlots) ~= "function" then
_G.checkError = "GetTotalBagSlots не является глобальной функцией"
return false
end
local expected = 0
for bag = 0, 4 do
local slots = GetContainerNumSlots(bag)
if type(slots) == "number" and slots > 0 then
expected = expected + slots
end
end
local ok, total = pcall(_G.GetTotalBagSlots)
if not ok then
_G.checkError = "Ошибка вызова GetTotalBagSlots: " .. tostring(total)
return false
end
if type(total) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if total ~= expected then
_G.checkError = "Общее количество ячеек не совпадает с суммой по сумкам 0-4"
return false
end
return true
end,
}

ns_llua['lua'][172] = {
type = "commenttest",
title = "Тест 167-5: функция GetTotalFreeBagSlots",
helpModules = {167, 45, 31, 65},
preloadVars = {
{var = "GetTotalFreeBagSlots", desc = "GetTotalFreeBagSlots очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 167-5: функция GetTotalFreeBagSlots</h>
<t>Создай глобальную функцию <k>GetTotalFreeBagSlots()</k>.</t>
<t>Функция должна вернуть общее количество свободных ячеек во всех сумках от 0 до 4.</t>
<t>Используй цикл и:</t>
<code>
GetContainerNumFreeSlots(bag)
</code>
<t>Если функция вернула <k>nil</k>, используй <n>0</n>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetTotalFreeBagSlots()
]=],
requireKeywords = {
"GetTotalFreeBagSlots",
"function",
"for",
"GetContainerNumFreeSlots",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetTotalFreeBagSlots) ~= "function" then
_G.checkError = "GetTotalFreeBagSlots не является глобальной функцией"
return false
end
local expected = 0
for bag = 0, 4 do
local freeSlots = GetContainerNumFreeSlots(bag)
if type(freeSlots) == "number" and freeSlots > 0 then
expected = expected + freeSlots
end
end
local ok, freeTotal = pcall(_G.GetTotalFreeBagSlots)
if not ok then
_G.checkError = "Ошибка вызова GetTotalFreeBagSlots: " .. tostring(freeTotal)
return false
end
if type(freeTotal) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if freeTotal ~= expected then
_G.checkError = "Количество свободных ячеек не совпадает с суммой по сумкам 0-4"
return false
end
return true
end,
}

ns_llua['lua'][173] = {
type = "info",
title = "Предметы в сумках",
helpModules = {167, 65},
content = [=[
<h>Предметы в сумках</h>
<t>Чтобы получить предмет в сумке, нужны два аргумента: ID сумки и номер ячейки.</t>
<h>GetContainerItemLink</h>
<code>
/run local link = GetContainerItemLink(0, 1); print(link or "Пусто")
</code>
<t>Если ячейка пустая, функция вернёт <k>nil</k>.</t>
<t>Если предмет есть, функция вернёт строку-ссылку предмета. Такая ссылка содержит цвет, имя и внутреннюю информацию о предмете.</t>
<h>GetContainerItemInfo</h>
<code>
/run local texture, count = GetContainerItemInfo(0, 1); print(texture, count)
</code>
<t>Функция возвращает несколько значений. Основные:</t>
<c>texture</c> — иконка предмета.
<c>count</c> — количество предметов в ячейке.
<c>locked</c> — заблокирован ли предмет.
<c>quality</c> — качество предмета.
<h>GetContainerItemID</h>
<code>
/run print(GetContainerItemID(0, 1))
</code>
<t>Возвращает числовой ID предмета, если ячейка не пустая.</t>
<h>Перебор первой сумки</h>
<code>
/run local slots = GetContainerNumSlots(0) or 0; for slot = 1, slots do local link = GetContainerItemLink(0, slot); if link then print(slot, link) end end
</code>
<h>Подсчёт занятых ячеек</h>
<code>
/run local slots = GetContainerNumSlots(0) or 0; local used = 0; for slot = 1, slots do if GetContainerItemLink(0, slot) then used = used + 1 end end; print("Занято:", used)
</code>
<w>Примечание:</w> ссылка на предмет может содержать цветовые коды и специальные символы. Это нормально: именно такие ссылки WoW использует для показа предметов в чате.
]=],
}

ns_llua['lua'][174] = {
type = "vartest",
title = "Тест 173-1: первый слот рюкзака",
helpModules = {173, 167, 65},
tasks = {
{
var = "backpackSlots",
desc = 'Создай глобальную переменную backpackSlots = GetContainerNumSlots(0) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "backpackFirstLink",
desc = 'Создай глобальную переменную backpackFirstLink = GetContainerItemLink(0, 1) or "empty"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
},
}

ns_llua['lua'][175] = {
type = "vartest",
title = "Тест 173-2: ID и количество предмета",
helpModules = {173, 167, 65},
tasks = {
{
var = "backpackFirstID",
desc = 'Создай глобальную переменную backpackFirstID = GetContainerItemID(0, 1) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "backpackFirstCount",
desc = 'Создай глобальную переменную backpackFirstCount = select(2, GetContainerItemInfo(0, 1)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][176] = {
type = "commenttest",
title = "Тест 173-3: функция GetContainerItemLinkSafe",
helpModules = {173, 45, 65},
preloadVars = {
{var = "GetContainerItemLinkSafe", desc = "GetContainerItemLinkSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 173-3: функция GetContainerItemLinkSafe</h>
<t>Создай глобальную функцию <k>GetContainerItemLinkSafe(bag, slot)</k>.</t>
<t>Если <k>bag</k> или <k>slot</k> не являются числами, функция должна вернуть строку:</t>
<s>"empty"</s>
<t>Иначе функция должна получить ссылку на предмет через:</t>
<code>
GetContainerItemLink(bag, slot)
</code>
<t>Если результат не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"empty"</s>
<t>Иначе функция должна вернуть саму ссылку на предмет.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetContainerItemLinkSafe(bag, slot)
]=],
requireKeywords = {
"GetContainerItemLinkSafe",
"function",
"GetContainerItemLink",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetContainerItemLinkSafe) ~= "function" then
_G.checkError = "GetContainerItemLinkSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetContainerItemLinkSafe, 0, 1)
if not ok1 then
_G.checkError = "Ошибка вызова GetContainerItemLinkSafe(0, 1): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для bag = 0 и slot = 1 функция должна вернуть строку"
return false
end
local ok2, result2 = pcall(_G.GetContainerItemLinkSafe, "bad", 1)
if not ok2 or result2 ~= "empty" then
_G.checkError = "Для нечислового bag функция должна вернуть 'empty'"
return false
end
local ok3, result3 = pcall(_G.GetContainerItemLinkSafe, 0, "bad")
if not ok3 or result3 ~= "empty" then
_G.checkError = "Для нечислового slot функция должна вернуть 'empty'"
return false
end
return true
end,
}

ns_llua['lua'][177] = {
type = "commenttest",
title = "Тест 173-4: функция GetContainerItemCountSafe",
helpModules = {173, 45, 65},
preloadVars = {
{var = "GetContainerItemCountSafe", desc = "GetContainerItemCountSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 173-4: функция GetContainerItemCountSafe</h>
<t>Создай глобальную функцию <k>GetContainerItemCountSafe(bag, slot)</k>.</t>
<t>Если <k>bag</k> или <k>slot</k> не являются числами, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить количество предметов через:</t>
<code>
select(2, GetContainerItemInfo(bag, slot))
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть само количество.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetContainerItemCountSafe(bag, slot)
]=],
requireKeywords = {
"GetContainerItemCountSafe",
"function",
"GetContainerItemInfo",
"select",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetContainerItemCountSafe) ~= "function" then
_G.checkError = "GetContainerItemCountSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetContainerItemCountSafe, 0, 1)
if not ok1 then
_G.checkError = "Ошибка вызова GetContainerItemCountSafe(0, 1): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < 0 then
_G.checkError = "Для bag = 0 и slot = 1 функция должна вернуть число больше или равное нулю"
return false
end
local ok2, result2 = pcall(_G.GetContainerItemCountSafe, "bad", 1)
if not ok2 or result2 ~= 0 then
_G.checkError = "Для нечислового bag функция должна вернуть 0"
return false
end
local ok3, result3 = pcall(_G.GetContainerItemCountSafe, 0, "bad")
if not ok3 or result3 ~= 0 then
_G.checkError = "Для нечислового slot функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][178] = {
type = "commenttest",
title = "Тест 173-5: функция CountFilledSlotsInBag",
helpModules = {173, 45, 31, 65},
preloadVars = {
{var = "CountFilledSlotsInBag", desc = "CountFilledSlotsInBag очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 173-5: функция CountFilledSlotsInBag</h>
<t>Создай глобальную функцию <k>CountFilledSlotsInBag(bag)</k>.</t>
<t>Если <k>bag</k> не является числом, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить количество ячеек через:</t>
<code>
GetContainerNumSlots(bag)
</code>
<t>Если количество ячеек не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна пройти циклом по всем ячейкам и посчитать, сколько из них не пустые.</t>
<t>Ячейка считается не пустой, если:</t>
<code>
GetContainerItemLink(bag, slot)
</code>
<t>вернул значение, отличное от <k>nil</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CountFilledSlotsInBag(bag)
]=],
requireKeywords = {
"CountFilledSlotsInBag",
"function",
"GetContainerNumSlots",
"GetContainerItemLink",
"for",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CountFilledSlotsInBag) ~= "function" then
_G.checkError = "CountFilledSlotsInBag не является глобальной функцией"
return false
end
local function countExpected(bag)
if type(bag) ~= "number" then
return 0
end
local slots = GetContainerNumSlots(bag)
if type(slots) ~= "number" or slots < 0 then
return 0
end
local expected = 0
for slot = 1, slots do
if GetContainerItemLink(bag, slot) then
expected = expected + 1
end
end
return expected
end
local ok1, result1 = pcall(_G.CountFilledSlotsInBag, 0)
if not ok1 then
_G.checkError = "Ошибка вызова CountFilledSlotsInBag(0): " .. tostring(result1)
return false
end
local expected1 = countExpected(0)
if result1 ~= expected1 then
_G.checkError = "Количество занятых ячеек в сумке 0 не совпадает с ожидаемым"
return false
end
local ok2, result2 = pcall(_G.CountFilledSlotsInBag, -1)
if not ok2 or result2 ~= 0 then
_G.checkError = "Для сумки -1 функция должна вернуть 0"
return false
end
local ok3, result3 = pcall(_G.CountFilledSlotsInBag, "bad")
if not ok3 or result3 ~= 0 then
_G.checkError = "Для нечислового bag функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][179] = {
type = "info",
title = "Информация о предмете",
helpModules = {173, 65},
content = [=[
<h>Информация о предмете</h>
<t>Функция <k>GetItemInfo</k> возвращает много данных о предмете: название, ссылку, качество, уровень предмета и другое.</t>
<code>
/run local name, link, quality, itemLevel = GetItemInfo(6948); print(name, link, quality, itemLevel)
</code>
<t>Здесь <n>6948</n> — это ID камня возвращения.</t>
<w>Важно:</w> если предмет ещё не загружен в кэш клиента, функция может вернуть <k>nil</k>.
<h>Что возвращает GetItemInfo</h>
<t>Основные значения:</t>
<c>name</c> — название предмета.
<c>link</c> — ссылка на предмет.
<c>quality</c> — числовое качество.
<c>itemLevel</c> — уровень предмета.
<c>reqLevel</c> — требуемый уровень.
<c>itemType</c> — тип предмета.
<c>itemSubType</c> — подтип предмета.
<c>stackCount</c> — максимальный размер стопки.
<h>Качество предмета</h>
<t>Качество обычно такое:</t>
<c>0</c> — бедный.
<c>1</c> — обычный.
<c>2</c> — необычный.
<c>3</c> — редкий.
<c>4</c> — эпический.
<c>5</c> — легендарный.
<h>Цвет качества</h>
<code>
/run local name, link, quality = GetItemInfo(6948); if name and ITEM_QUALITY_COLORS[quality] then print(ITEM_QUALITY_COLORS[quality].hex .. name .. "|r") end
</code>
<h>Количество предметов</h>
<code>
/run print(GetItemCount(6948))
</code>
<t>Функция <k>GetItemCount</k> возвращает количество таких предметов в сумках.</t>
<h>Безопасный шаблон</h>
<code>
/run local name, link, quality, itemLevel = GetItemInfo(6948); name = name or "Неизвестно"; itemLevel = itemLevel or 0; print(string.format("%s, ilvl %d", name, itemLevel))
</code>
]=],
}

ns_llua['lua'][180] = {
type = "vartest",
title = "Тест 179-1: камень возвращения",
helpModules = {179, 65},
tasks = {
{
var = "hearthstoneName",
desc = 'Создай глобальную переменную hearthstoneName = GetItemInfo(6948) or "Неизвестно"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "hearthstoneQuality",
desc = 'Создай глобальную переменную hearthstoneQuality = select(3, GetItemInfo(6948)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][181] = {
type = "vartest",
title = "Тест 179-2: количество и уровень предмета",
helpModules = {179, 65},
tasks = {
{
var = "hearthstoneCount",
desc = 'Создай глобальную переменную hearthstoneCount = GetItemCount(6948) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "hearthstoneItemLevel",
desc = 'Создай глобальную переменную hearthstoneItemLevel = select(4, GetItemInfo(6948)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][182] = {
type = "commenttest",
title = "Тест 179-3: функция GetItemNameSafe",
helpModules = {179, 45, 65},
preloadVars = {
{var = "GetItemNameSafe", desc = "GetItemNameSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 179-3: функция GetItemNameSafe</h>
<t>Создай глобальную функцию <k>GetItemNameSafe(itemID)</k>.</t>
<t>Если <k>itemID</k> не является числом, функция должна вернуть строку:</t>
<s>"Неизвестно"</s>
<t>Иначе функция должна получить имя предмета через:</t>
<code>
GetItemInfo(itemID)
</code>
<t>Если имя не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"Неизвестно"</s>
<t>Иначе функция должна вернуть имя предмета.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetItemNameSafe(itemID)
]=],
requireKeywords = {
"GetItemNameSafe",
"function",
"GetItemInfo",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetItemNameSafe) ~= "function" then
_G.checkError = "GetItemNameSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetItemNameSafe, 6948)
if not ok1 then
_G.checkError = "Ошибка вызова GetItemNameSafe(6948): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для itemID = 6948 функция должна вернуть строку"
return false
end
local ok2, result2 = pcall(_G.GetItemNameSafe, "bad")
if not ok2 or result2 ~= "Неизвестно" then
_G.checkError = "Для нечислового itemID функция должна вернуть 'Неизвестно'"
return false
end
return true
end,
}

ns_llua['lua'][183] = {
type = "commenttest",
title = "Тест 179-4: функция GetItemQualitySafe",
helpModules = {179, 45, 65},
preloadVars = {
{var = "GetItemQualitySafe", desc = "GetItemQualitySafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 179-4: функция GetItemQualitySafe</h>
<t>Создай глобальную функцию <k>GetItemQualitySafe(itemID)</k>.</t>
<t>Если <k>itemID</k> не является числом, функция должна вернуть <n>-1</n>.</t>
<t>Иначе функция должна получить качество предмета через:</t>
<code>
select(3, GetItemInfo(itemID))
</code>
<t>Если качество не является числом или меньше нуля, функция должна вернуть <n>-1</n>.</t>
<t>Иначе функция должна вернуть качество предмета.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetItemQualitySafe(itemID)
]=],
requireKeywords = {
"GetItemQualitySafe",
"function",
"GetItemInfo",
"select",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetItemQualitySafe) ~= "function" then
_G.checkError = "GetItemQualitySafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetItemQualitySafe, 6948)
if not ok1 then
_G.checkError = "Ошибка вызова GetItemQualitySafe(6948): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < -1 or result1 > 5 then
_G.checkError = "Для itemID = 6948 функция должна вернуть число от -1 до 5"
return false
end
local ok2, result2 = pcall(_G.GetItemQualitySafe, "bad")
if not ok2 or result2 ~= -1 then
_G.checkError = "Для нечислового itemID функция должна вернуть -1"
return false
end
return true
end,
}

ns_llua['lua'][184] = {
type = "commenttest",
title = "Тест 179-5: функция GetItemCountSafe",
helpModules = {179, 45, 65},
preloadVars = {
{var = "GetItemCountSafe", desc = "GetItemCountSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 179-5: функция GetItemCountSafe</h>
<t>Создай глобальную функцию <k>GetItemCountSafe(itemID)</k>.</t>
<t>Если <k>itemID</k> не является числом, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить количество предметов через:</t>
<code>
GetItemCount(itemID)
</code>
<t>Если количество не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть количество предметов.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetItemCountSafe(itemID)
]=],
requireKeywords = {
"GetItemCountSafe",
"function",
"GetItemCount",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetItemCountSafe) ~= "function" then
_G.checkError = "GetItemCountSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetItemCountSafe, 6948)
if not ok1 then
_G.checkError = "Ошибка вызова GetItemCountSafe(6948): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < 0 then
_G.checkError = "Для itemID = 6948 функция должна вернуть число больше или равное нулю"
return false
end
local ok2, result2 = pcall(_G.GetItemCountSafe, "bad")
if not ok2 or result2 ~= 0 then
_G.checkError = "Для нечислового itemID функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][185] = {
type = "info",
title = "Экипировка игрока",
helpModules = {179, 173, 65},
content = [=[
<h>Экипировка игрока</h>
<t>Экипировка доступна через слоты. У каждого слота есть строковое имя.</t>
<h>Основные слоты</h>
<c>"HeadSlot"</c> — голова.
<c>"NeckSlot"</c> — шея.
<c>"ShoulderSlot"</c> — плечи.
<c>"BackSlot"</c> — спина.
<c>"ChestSlot"</c> — грудь.
<c>"WristSlot"</c> — запястья.
<c>"HandsSlot"</c> — руки.
<c>"WaistSlot"</c> — пояс.
<c>"LegsSlot"</c> — ноги.
<c>"FeetSlot"</c> — ступни.
<c>"Finger0Slot"</c> — первое кольцо.
<c>"Finger1Slot"</c> — второе кольцо.
<c>"Trinket0Slot"</c> — первая бижутерия.
<c>"Trinket1Slot"</c> — вторая бижутерия.
<c>"MainHandSlot"</c> — правая рука.
<c>"SecondaryHandSlot"</c> — левая рука.
<h>GetInventorySlotInfo</h>
<code>
/run local slotId = GetInventorySlotInfo("HeadSlot"); print(slotId)
</code>
<t>Функция возвращает числовой ID слота.</t>
<h>Предмет в слоте</h>
<code>
/run local slotId = GetInventorySlotInfo("HeadSlot"); local link = GetInventoryItemLink("player", slotId); print(link or "Пусто")
</code>
<h>Количество предметов в слоте</h>
<code>
/run local slotId = GetInventorySlotInfo("MainHandSlot"); print(GetInventoryItemCount("player", slotId))
</code>
<h>Текстура предмета</h>
<code>
/run local slotId = GetInventorySlotInfo("ChestSlot"); print(GetInventoryItemTexture("player", slotId))
</code>
<h>Перебор нескольких слотов</h>
<code>
/run local slots = {"HeadSlot", "ChestSlot", "MainHandSlot"}; for _, slotName in ipairs(slots) do local slotId = GetInventorySlotInfo(slotName); local link = GetInventoryItemLink("player", slotId); print(slotName, link or "пусто") end
</code>
]=],
}

ns_llua['lua'][186] = {
type = "vartest",
title = "Тест 185-1: ID слотов экипировки",
helpModules = {185, 65},
tasks = {
{
var = "headSlotID",
desc = 'Создай глобальную переменную headSlotID = GetInventorySlotInfo("HeadSlot") or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "chestSlotID",
desc = 'Создай глобальную переменную chestSlotID = GetInventorySlotInfo("ChestSlot") or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][187] = {
type = "vartest",
title = "Тест 185-2: предметы в слотах",
helpModules = {185, 65},
tasks = {
{
var = "headItemLink",
desc = 'Создай глобальную переменную headItemLink = GetInventoryItemLink("player", GetInventorySlotInfo("HeadSlot")) or "empty"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "mainHandItemLink",
desc = 'Создай глобальную переменную mainHandItemLink = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot")) or "empty"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
},
}

ns_llua['lua'][188] = {
type = "commenttest",
title = "Тест 185-3: функция GetInventorySlotIDSafe",
helpModules = {185, 45, 65},
preloadVars = {
{var = "GetInventorySlotIDSafe", desc = "GetInventorySlotIDSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 185-3: функция GetInventorySlotIDSafe</h>
<t>Создай глобальную функцию <k>GetInventorySlotIDSafe(slotName)</k>.</t>
<t>Если <k>slotName</k> не является строкой, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить ID слота через:</t>
<code>
GetInventorySlotInfo(slotName)
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть ID слота.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetInventorySlotIDSafe(slotName)
]=],
requireKeywords = {
"GetInventorySlotIDSafe",
"function",
"GetInventorySlotInfo",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetInventorySlotIDSafe) ~= "function" then
_G.checkError = "GetInventorySlotIDSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetInventorySlotIDSafe, "HeadSlot")
if not ok1 then
_G.checkError = "Ошибка вызова GetInventorySlotIDSafe('HeadSlot'): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 <= 0 then
_G.checkError = "Для HeadSlot функция должна вернуть число больше нуля"
return false
end
local ok2, result2 = pcall(_G.GetInventorySlotIDSafe, "BadSlot")
if not ok2 or result2 ~= 0 then
_G.checkError = "Для BadSlot функция должна вернуть 0"
return false
end
local ok3, result3 = pcall(_G.GetInventorySlotIDSafe, 123)
if not ok3 or result3 ~= 0 then
_G.checkError = "Для нестрокового slotName функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][189] = {
type = "commenttest",
title = "Тест 185-4: функция GetInventoryItemLinkSafe",
helpModules = {185, 45, 65},
preloadVars = {
{var = "GetInventoryItemLinkSafe", desc = "GetInventoryItemLinkSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 185-4: функция GetInventoryItemLinkSafe</h>
<t>Создай глобальную функцию <k>GetInventoryItemLinkSafe(slotName)</k>.</t>
<t>Если <k>slotName</k> не является строкой, функция должна вернуть строку:</t>
<s>"empty"</s>
<t>Иначе функция должна получить ID слота через:</t>
<code>
GetInventorySlotInfo(slotName)
</code>
<t>Если ID слота не является числом или меньше нуля, функция должна вернуть:</t>
<s>"empty"</s>
<t>Иначе функция должна получить ссылку на предмет через:</t>
<code>
GetInventoryItemLink("player", slotID)
</code>
<t>Если ссылка не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"empty"</s>
<t>Иначе функция должна вернуть ссылку на предмет.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetInventoryItemLinkSafe(slotName)
]=],
requireKeywords = {
"GetInventoryItemLinkSafe",
"function",
"GetInventorySlotInfo",
"GetInventoryItemLink",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetInventoryItemLinkSafe) ~= "function" then
_G.checkError = "GetInventoryItemLinkSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetInventoryItemLinkSafe, "HeadSlot")
if not ok1 then
_G.checkError = "Ошибка вызова GetInventoryItemLinkSafe('HeadSlot'): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для HeadSlot функция должна вернуть строку"
return false
end
local ok2, result2 = pcall(_G.GetInventoryItemLinkSafe, "BadSlot")
if not ok2 or result2 ~= "empty" then
_G.checkError = "Для BadSlot функция должна вернуть 'empty'"
return false
end
local ok3, result3 = pcall(_G.GetInventoryItemLinkSafe, 123)
if not ok3 or result3 ~= "empty" then
_G.checkError = "Для нестрокового slotName функция должна вернуть 'empty'"
return false
end
return true
end,
}

ns_llua['lua'][190] = {
type = "commenttest",
title = "Тест 185-5: функция CountEquippedSlots",
helpModules = {185, 45, 31, 65},
preloadVars = {
{var = "CountEquippedSlots", desc = "CountEquippedSlots очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 185-5: функция CountEquippedSlots</h>
<t>Создай глобальную функцию <k>CountEquippedSlots(slotNames)</k>.</t>
<t>Аргумент <k>slotNames</k> — это таблица со строками-названиями слотов экипировки.</t>
<t>Если <k>slotNames</k> не является таблицей, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна пройти по таблице через <k>ipairs</k> и посчитать, сколько слотов содержат предмет.</t>
<t>Для каждого имени слота используй:</t>
<c>GetInventorySlotInfo(slotName)</c>
<c>GetInventoryItemLink("player", slotID)</c>
<t>Слот считается надетым, если ссылка на предмет является непустой строкой.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CountEquippedSlots(slotNames)
]=],
requireKeywords = {
"CountEquippedSlots",
"function",
"ipairs",
"GetInventorySlotInfo",
"GetInventoryItemLink",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CountEquippedSlots) ~= "function" then
_G.checkError = "CountEquippedSlots не является глобальной функцией"
return false
end
local function expectedCount(slotNames)
if type(slotNames) ~= "table" then
return 0
end
local expected = 0
for _, slotName in ipairs(slotNames) do
if type(slotName) == "string" then
local slotID = GetInventorySlotInfo(slotName)
if type(slotID) == "number" and slotID >= 0 then
local link = GetInventoryItemLink("player", slotID)
if type(link) == "string" and link ~= "" then
expected = expected + 1
end
end
end
end
return expected
end
local tests = {
{
input = {"HeadSlot", "ChestSlot"},
},
{
input = {},
},
{
input = "bad",
},
}
for i, test in ipairs(tests) do
local expected = expectedCount(test.input)
local ok, result = pcall(_G.CountEquippedSlots, test.input)
if not ok or result ~= expected then
_G.checkError = "Тест " .. i .. " функции CountEquippedSlots не пройден"
return false
end
end
return true
end,
}

ns_llua['lua'][191] = {
type = "info",
title = "Информация о заклинаниях",
helpModules = {65, 45, 10},
content = [=[
<h>Информация о заклинаниях</h>
<t>Функция <k>GetSpellInfo</k> возвращает данные о заклинании по ID или названию.</t>
<code>
/run local name, rank, icon, cost, isFunnel, powerType, castTime = GetSpellInfo(6603); print(name, castTime)
</code>
<t>Здесь <n>6603</n> — ID базовой автоматической атаки.</t>
<w>Важно:</w> если заклинание неизвестно или данные ещё не доступны, функция может вернуть <k>nil</k>.
<h>Что возвращает GetSpellInfo</h>
<t>Основные значения:</t>
<c>name</c> — название заклинания.
<c>rank</c> — ранг.
<c>icon</c> — иконка.
<c>cost</c> — стоимость.
<c>powerType</c> — тип ресурса.
<c>castTime</c> — время каста в миллисекундах.
<h>SpellID лучше названия</h>
<t>Название заклинания зависит от языка клиента:</t>
<code>
/run print(GetSpellInfo(6603))
</code>
<t>ID заклинания одинаковый для всех клиентов, поэтому для логики лучше использовать ID.</t>
<h>Иконка заклинания</h>
<code>
/run print(GetSpellTexture(6603))
</code>
<h>Безопасный шаблон</h>
<code>
/run local name = GetSpellInfo(6603) or "Неизвестно"; print(name)
</code>
]=],
}

ns_llua['lua'][192] = {
type = "vartest",
title = "Тест 191-1: имя и иконка заклинания",
helpModules = {191, 65},
tasks = {
{
var = "spellName",
desc = 'Создай глобальную переменную spellName = GetSpellInfo(6603) or "Неизвестно"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "spellTexture",
desc = 'Создай глобальную переменную spellTexture = GetSpellTexture(6603) or ""',
check = function(value)
return type(value) == "string"
end,
},
},
}

ns_llua['lua'][193] = {
type = "vartest",
title = "Тест 191-2: стоимость и время каста",
helpModules = {191, 65},
tasks = {
{
var = "spellCost",
desc = 'Создай глобальную переменную spellCost = select(4, GetSpellInfo(6603)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "spellCastTime",
desc = 'Создай глобальную переменную spellCastTime = select(7, GetSpellInfo(6603)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][194] = {
type = "commenttest",
title = "Тест 191-3: функция GetSpellNameSafe",
helpModules = {191, 45, 65},
preloadVars = {
{var = "GetSpellNameSafe", desc = "GetSpellNameSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 191-3: функция GetSpellNameSafe</h>
<t>Создай глобальную функцию <k>GetSpellNameSafe(spellID)</k>.</t>
<t>Если <k>spellID</k> не является числом, функция должна вернуть строку:</t>
<s>"Неизвестно"</s>
<t>Иначе функция должна получить имя заклинания через:</t>
<code>
GetSpellInfo(spellID)
</code>
<t>Если имя не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"Неизвестно"</s>
<t>Иначе функция должна вернуть имя заклинания.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetSpellNameSafe(spellID)
]=],
requireKeywords = {
"GetSpellNameSafe",
"function",
"GetSpellInfo",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetSpellNameSafe) ~= "function" then
_G.checkError = "GetSpellNameSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetSpellNameSafe, 6603)
if not ok1 then
_G.checkError = "Ошибка вызова GetSpellNameSafe(6603): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для spellID = 6603 функция должна вернуть строку"
return false
end
local ok2, result2 = pcall(_G.GetSpellNameSafe, "bad")
if not ok2 or result2 ~= "Неизвестно" then
_G.checkError = "Для нечислового spellID функция должна вернуть 'Неизвестно'"
return false
end
return true
end,
}

ns_llua['lua'][195] = {
type = "commenttest",
title = "Тест 191-4: функция GetSpellTextureSafe",
helpModules = {191, 45, 65},
preloadVars = {
{var = "GetSpellTextureSafe", desc = "GetSpellTextureSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 191-4: функция GetSpellTextureSafe</h>
<t>Создай глобальную функцию <k>GetSpellTextureSafe(spellID)</k>.</t>
<t>Если <k>spellID</k> не является числом, функция должна вернуть строку:</t>
<s>"empty"</s>
<t>Иначе функция должна получить иконку заклинания через:</t>
<code>
GetSpellTexture(spellID)
</code>
<t>Если результат не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"empty"</s>
<t>Иначе функция должна вернуть путь к иконке.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetSpellTextureSafe(spellID)
]=],
requireKeywords = {
"GetSpellTextureSafe",
"function",
"GetSpellTexture",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetSpellTextureSafe) ~= "function" then
_G.checkError = "GetSpellTextureSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetSpellTextureSafe, 6603)
if not ok1 then
_G.checkError = "Ошибка вызова GetSpellTextureSafe(6603): " .. tostring(result1)
return false
end
if type(result1) ~= "string" then
_G.checkError = "Для spellID = 6603 функция должна вернуть строку"
return false
end
local ok2, result2 = pcall(_G.GetSpellTextureSafe, "bad")
if not ok2 or result2 ~= "empty" then
_G.checkError = "Для нечислового spellID функция должна вернуть 'empty'"
return false
end
return true
end,
}

ns_llua['lua'][196] = {
type = "commenttest",
title = "Тест 191-5: функция GetSpellCastTimeSafe",
helpModules = {191, 45, 65},
preloadVars = {
{var = "GetSpellCastTimeSafe", desc = "GetSpellCastTimeSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 191-5: функция GetSpellCastTimeSafe</h>
<t>Создай глобальную функцию <k>GetSpellCastTimeSafe(spellID)</k>.</t>
<t>Если <k>spellID</k> не является числом, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить время каста через:</t>
<code>
select(7, GetSpellInfo(spellID))
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть время каста.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetSpellCastTimeSafe(spellID)
]=],
requireKeywords = {
"GetSpellCastTimeSafe",
"function",
"GetSpellInfo",
"select",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetSpellCastTimeSafe) ~= "function" then
_G.checkError = "GetSpellCastTimeSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetSpellCastTimeSafe, 6603)
if not ok1 then
_G.checkError = "Ошибка вызова GetSpellCastTimeSafe(6603): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < 0 then
_G.checkError = "Для spellID = 6603 функция должна вернуть число больше или равное нулю"
return false
end
local ok2, result2 = pcall(_G.GetSpellCastTimeSafe, "bad")
if not ok2 or result2 ~= 0 then
_G.checkError = "Для нечислового spellID функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][197] = {
type = "info",
title = "Кулдауны заклинаний",
helpModules = {191, 65, 10},
content = [=[
<h>Кулдауны заклинаний</h>
<t>Функция <k>GetSpellCooldown</k> возвращает информацию о восстановлении заклинания.</t>
<code>
/run local start, duration = GetSpellCooldown(6603); print(start, duration)
</code>
<h>Что означают значения</h>
<c>start</c> — момент начала кулдауна по <k>GetTime</k>.
<c>duration</c> — длительность кулдауна в секундах.
<c>enabled</c> — доступно ли заклинание.
<h>Если заклинание готово</h>
<t>Обычно если <k>start</k> равно <n>0</n>, кулдауна нет.</t>
<code>
/run local start, duration = GetSpellCooldown(6603); if start == 0 then print("Готово") else print("Кулдаун") end
</code>
<h>Остаток времени</h>
<code>
/run local start, duration = GetSpellCooldown(6603); local remaining = 0; if start and duration and start > 0 then remaining = start + duration - GetTime(); if remaining < 0 then remaining = 0 end end; print(string.format("Осталось: %.1f", remaining))
</code>
<h>Безопасный шаблон</h>
<code>
/run local start = GetSpellCooldown(6603) or 0; if start == 0 then print("Кулдауна нет") end
</code>
]=],
}

ns_llua['lua'][198] = {
type = "vartest",
title = "Тест 197-1: старт и длительность кулдауна",
helpModules = {197, 65},
tasks = {
{
var = "spellCooldownStart",
desc = 'Создай глобальную переменную spellCooldownStart = GetSpellCooldown(6603) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "spellCooldownDuration",
desc = 'Создай глобальную переменную spellCooldownDuration = select(2, GetSpellCooldown(6603)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][199] = {
type = "vartest",
title = "Тест 197-2: готовность заклинания",
helpModules = {197, 15, 65},
tasks = {
{
var = "spellIsReady",
desc = 'Создай глобальную переменную spellIsReady = ((GetSpellCooldown(6603) or 0) == 0)',
check = function(value)
return type(value) == "boolean"
end,
},
{
var = "spellCooldownEnabled",
desc = 'Создай глобальную переменную spellCooldownEnabled = select(3, GetSpellCooldown(6603)) or 1',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][200] = {
type = "commenttest",
title = "Тест 197-3: функция GetSpellCooldownStartSafe",
helpModules = {197, 45, 65},
preloadVars = {
{var = "GetSpellCooldownStartSafe", desc = "GetSpellCooldownStartSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 197-3: функция GetSpellCooldownStartSafe</h>
<t>Создай глобальную функцию <k>GetSpellCooldownStartSafe(spellID)</k>.</t>
<t>Если <k>spellID</k> не является числом, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить старт кулдауна через:</t>
<code>
GetSpellCooldown(spellID)
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть старт кулдауна.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetSpellCooldownStartSafe(spellID)
]=],
requireKeywords = {
"GetSpellCooldownStartSafe",
"function",
"GetSpellCooldown",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetSpellCooldownStartSafe) ~= "function" then
_G.checkError = "GetSpellCooldownStartSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetSpellCooldownStartSafe, 6603)
if not ok1 then
_G.checkError = "Ошибка вызова GetSpellCooldownStartSafe(6603): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < 0 then
_G.checkError = "Для spellID = 6603 функция должна вернуть число больше или равное нулю"
return false
end
local ok2, result2 = pcall(_G.GetSpellCooldownStartSafe, "bad")
if not ok2 or result2 ~= 0 then
_G.checkError = "Для нечислового spellID функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][201] = {
type = "commenttest",
title = "Тест 197-4: функция GetSpellCooldownDurationSafe",
helpModules = {197, 45, 65},
preloadVars = {
{var = "GetSpellCooldownDurationSafe", desc = "GetSpellCooldownDurationSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 197-4: функция GetSpellCooldownDurationSafe</h>
<t>Создай глобальную функцию <k>GetSpellCooldownDurationSafe(spellID)</k>.</t>
<t>Если <k>spellID</k> не является числом, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить длительность кулдауна через:</t>
<code>
select(2, GetSpellCooldown(spellID))
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть длительность кулдауна.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetSpellCooldownDurationSafe(spellID)
]=],
requireKeywords = {
"GetSpellCooldownDurationSafe",
"function",
"GetSpellCooldown",
"select",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetSpellCooldownDurationSafe) ~= "function" then
_G.checkError = "GetSpellCooldownDurationSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetSpellCooldownDurationSafe, 6603)
if not ok1 then
_G.checkError = "Ошибка вызова GetSpellCooldownDurationSafe(6603): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < 0 then
_G.checkError = "Для spellID = 6603 функция должна вернуть число больше или равное нулю"
return false
end
local ok2, result2 = pcall(_G.GetSpellCooldownDurationSafe, "bad")
if not ok2 or result2 ~= 0 then
_G.checkError = "Для нечислового spellID функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][202] = {
type = "commenttest",
title = "Тест 197-5: функция GetSpellCooldownRemaining",
helpModules = {197, 45, 10, 65},
preloadVars = {
{var = "GetSpellCooldownRemaining", desc = "GetSpellCooldownRemaining очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 197-5: функция GetSpellCooldownRemaining</h>
<t>Создай глобальную функцию <k>GetSpellCooldownRemaining(spellID)</k>.</t>
<t>Если <k>spellID</k> не является числом, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить <k>start</k> и <k>duration</k> через:</t>
<code>
GetSpellCooldown(spellID)
</code>
<t>Если <k>start</k> не является числом или равен нулю, функция должна вернуть <n>0</n>.</t>
<t>Если <k>duration</k> не является числом, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна посчитать остаток:</t>
<code>
start + duration - GetTime()
</code>
<t>Если остаток меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть остаток.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetSpellCooldownRemaining(spellID)
]=],
requireKeywords = {
"GetSpellCooldownRemaining",
"function",
"GetSpellCooldown",
"GetTime",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetSpellCooldownRemaining) ~= "function" then
_G.checkError = "GetSpellCooldownRemaining не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetSpellCooldownRemaining, 6603)
if not ok1 then
_G.checkError = "Ошибка вызова GetSpellCooldownRemaining(6603): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < 0 or result1 > 1000000 then
_G.checkError = "Для spellID = 6603 функция должна вернуть число от 0 до 1000000"
return false
end
local ok2, result2 = pcall(_G.GetSpellCooldownRemaining, "bad")
if not ok2 or result2 ~= 0 then
_G.checkError = "Для нечислового spellID функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][203] = {
type = "info",
title = "Баффы и дебаффы глубже",
helpModules = {107, 65, 45},
content = [=[
<h>Баффы и дебаффы глубже</h>
<t>Раньше мы получали только имя баффа или дебаффа. Теперь разберём дополнительные данные: стаки, длительность и время окончания.</t>
<h>UnitAura</h>
<code>
/run local name, rank, icon, count, debuffType, duration, expiration = UnitAura("player", 1, "HELPFUL"); print(name, count, duration, expiration)
</code>
<h>Основные возвращаемые значения</h>
<c>name</c> — название ауры.
<c>rank</c> — ранг.
<c>icon</c> — иконка.
<c>count</c> — количество стаков.
<c>debuffType</c> — тип дебаффа.
<c>duration</c> — длительность в секундах.
<c>expirationTime</c> — время окончания по <k>GetTime</k>.
<h>Баффы и дебаффы</h>
<code>
/run local name = UnitBuff("player", 1); print(name or "нет")
</code>
<code>
/run local name = UnitDebuff("player", 1); print(name or "нет")
</code>
<h>Остаток времени</h>
<code>
/run local name, _, _, _, _, duration, expiration = UnitBuff("player", 1); if name and expiration and expiration > 0 then print(name, math.floor(expiration - GetTime())) else print("Таймера нет") end
</code>
<t>Если <k>duration</k> и <k>expirationTime</k> равны нулю, таймер у ауры может отсутствовать.</t>
<h>Фильтры</h>
<c>"HELPFUL"</c> — баффы.
<c>"HARMFUL"</c> — дебаффы.
<t>Фильтры можно комбинировать, например искать только свои ауры, но в простых случаях достаточно <c>"HELPFUL"</c> и <c>"HARMFUL"</c>.</t>
]=],
}

ns_llua['lua'][204] = {
type = "vartest",
title = "Тест 203-1: первый бафф игрока",
helpModules = {203, 65},
tasks = {
{
var = "firstBuffName",
desc = 'Создай глобальную переменную firstBuffName = UnitBuff("player", 1) or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "firstBuffCount",
desc = 'Создай глобальную переменную firstBuffCount = select(4, UnitBuff("player", 1)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][205] = {
type = "vartest",
title = "Тест 203-2: первый дебафф игрока",
helpModules = {203, 65},
tasks = {
{
var = "firstDebuffName",
desc = 'Создай глобальную переменную firstDebuffName = UnitDebuff("player", 1) or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "firstDebuffType",
desc = 'Создай глобальную переменную firstDebuffType = select(5, UnitDebuff("player", 1)) or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
},
}

ns_llua['lua'][206] = {
type = "commenttest",
title = "Тест 203-3: функция GetAuraNameSafe",
helpModules = {203, 45, 65},
preloadVars = {
{var = "GetAuraNameSafe", desc = "GetAuraNameSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 203-3: функция GetAuraNameSafe</h>
<t>Создай глобальную функцию <k>GetAuraNameSafe(unit, index)</k>.</t>
<t>Если <k>unit</k> не является строкой или <k>index</k> не является числом, функция должна вернуть строку:</t>
<s>"нет"</s>
<t>Иначе функция должна получить имя баффа через:</t>
<code>
UnitBuff(unit, index)
</code>
<t>Если результат не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"нет"</s>
<t>Иначе функция должна вернуть имя баффа.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetAuraNameSafe(unit, index)
]=],
requireKeywords = {
"GetAuraNameSafe",
"function",
"UnitBuff",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetAuraNameSafe) ~= "function" then
_G.checkError = "GetAuraNameSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetAuraNameSafe, "player", 1)
if not ok1 then
_G.checkError = "Ошибка вызова GetAuraNameSafe('player', 1): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для player и index = 1 функция должна вернуть строку"
return false
end
local ok2, result2 = pcall(_G.GetAuraNameSafe, "ns_invalid_unit", 1)
if not ok2 or result2 ~= "нет" then
_G.checkError = "Для несуществующего юнита функция должна вернуть 'нет'"
return false
end
local ok3, result3 = pcall(_G.GetAuraNameSafe, "player", "bad")
if not ok3 or result3 ~= "нет" then
_G.checkError = "Для нечислового index функция должна вернуть 'нет'"
return false
end
return true
end,
}

ns_llua['lua'][207] = {
type = "commenttest",
title = "Тест 203-4: функция GetAuraRemainingSafe",
helpModules = {203, 45, 10, 65},
preloadVars = {
{var = "GetAuraRemainingSafe", desc = "GetAuraRemainingSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 203-4: функция GetAuraRemainingSafe</h>
<t>Создай глобальную функцию <k>GetAuraRemainingSafe(unit, index)</k>.</t>
<t>Если <k>unit</k> не является строкой или <k>index</k> не является числом, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить данные баффа через:</t>
<code>
UnitBuff(unit, index)
</code>
<t>Из полученных данных используй имя, длительность и время окончания.</t>
<t>Если имени нет, функция должна вернуть <n>0</n>.</t>
<t>Если время окончания не является числом или меньше либо равно нулю, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть остаток времени:</t>
<code>
expirationTime - GetTime()
</code>
<t>Если остаток меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetAuraRemainingSafe(unit, index)
]=],
requireKeywords = {
"GetAuraRemainingSafe",
"function",
"UnitBuff",
"GetTime",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetAuraRemainingSafe) ~= "function" then
_G.checkError = "GetAuraRemainingSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetAuraRemainingSafe, "player", 1)
if not ok1 then
_G.checkError = "Ошибка вызова GetAuraRemainingSafe('player', 1): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < 0 then
_G.checkError = "Для player и index = 1 функция должна вернуть число больше или равное нулю"
return false
end
local ok2, result2 = pcall(_G.GetAuraRemainingSafe, "ns_invalid_unit", 1)
if not ok2 or result2 ~= 0 then
_G.checkError = "Для несуществующего юнита функция должна вернуть 0"
return false
end
local ok3, result3 = pcall(_G.GetAuraRemainingSafe, "player", "bad")
if not ok3 or result3 ~= 0 then
_G.checkError = "Для нечислового index функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][208] = {
type = "commenttest",
title = "Тест 203-5: функция CountAurasWithFilter",
helpModules = {203, 45, 31, 65},
preloadVars = {
{var = "CountAurasWithFilter", desc = "CountAurasWithFilter очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 203-5: функция CountAurasWithFilter</h>
<t>Создай глобальную функцию <k>CountAurasWithFilter(unit, filter)</k>.</t>
<t>Если <k>unit</k> не является строкой или <k>filter</k> не является строкой, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна посчитать количество аур юнита с указанным фильтром.</t>
<t>Используй:</t>
<code>
UnitAura(unit, index, filter)
</code>
<t>Проверяй индексы от 1 до 40.</t>
<t>Если <k>UnitAura</k> вернул <k>nil</k>, прекрати подсчёт.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CountAurasWithFilter(unit, filter)
]=],
requireKeywords = {
"CountAurasWithFilter",
"function",
"UnitAura",
"for",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CountAurasWithFilter) ~= "function" then
_G.checkError = "CountAurasWithFilter не является глобальной функцией"
return false
end
local function countExpected(unit, filter)
if type(unit) ~= "string" or type(filter) ~= "string" then
return 0
end
local count = 0
for i = 1, 40 do
if not UnitAura(unit, i, filter) then
break
end
count = count + 1
end
return count
end
local expected1 = countExpected("player", "HELPFUL")
local ok1, result1 = pcall(_G.CountAurasWithFilter, "player", "HELPFUL")
if not ok1 or result1 ~= expected1 then
_G.checkError = "Для player и фильтра HELPFUL функция вернула неверное количество"
return false
end
local ok2, result2 = pcall(_G.CountAurasWithFilter, "ns_invalid_unit", "HELPFUL")
if not ok2 or result2 ~= 0 then
_G.checkError = "Для несуществующего юнита функция должна вернуть 0"
return false
end
local ok3, result3 = pcall(_G.CountAurasWithFilter, "player", 123)
if not ok3 or result3 ~= 0 then
_G.checkError = "Для нестрокового фильтра функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][209] = {
type = "info",
title = "Каст, каналы и угроза",
helpModules = {197, 203},
content = [=[
<h>Каст, каналы и угроза</h>
<t>WoW API позволяет проверить, кастует ли юнит заклинание или поддерживает канальное заклинание.</t>
<h>UnitCastingInfo</h>
<code>
/run local name, rank, text, startTime, endTime = UnitCastingInfo("player"); print(name or "нет")
</code>
<t>Если игрок ничего не кастует, функция вернёт <k>nil</k>.</t>
<h>UnitChannelInfo</h>
<t>Для канальных заклинаний используется <k>UnitChannelInfo</k>.</t>
<code>
/run local name, rank, text, startTime, endTime = UnitChannelInfo("player"); print(name or "нет")
</code>
<h>Время каста</h>
<t>Значения <k>startTime</k> и <k>endTime</k> обычно возвращаются в миллисекундах.</t>
<t><k>GetTime()</k> возвращает время в секундах, поэтому для сравнения секунды нужно умножить на 1000.</t>
<code>
/run local name, _, _, startTime, endTime = UnitCastingInfo("player"); if name then local remaining = (endTime / 1000) - GetTime(); print(string.format("Осталось: %.1f", remaining)) end
</code>
<h>UnitThreatSituation</h>
<t>Возвращает примерный статус угрозы.</t>
<code>
/run print(UnitThreatSituation("player"))
</code>
<h>InCombatLockdown</h>
<t>Показывает, находится ли интерфейс в состоянии боя с ограничениями.</t>
<code>
/run if InCombatLockdown() then print("Блокировка боя") else print("Вне блокировки") end
</code>
<w>Важно:</w> в бою многие действия интерфейса защищены. Позже мы отдельно разберём защищённые кнопки.
]=],
}

ns_llua['lua'][210] = {
type = "vartest",
title = "Тест 209-1: каст и канал игрока",
helpModules = {209, 65},
tasks = {
{
var = "playerCastName",
desc = 'Создай глобальную переменную playerCastName = UnitCastingInfo("player") or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "playerChannelName",
desc = 'Создай глобальную переменную playerChannelName = UnitChannelInfo("player") or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
},
}

ns_llua['lua'][211] = {
type = "vartest",
title = "Тест 209-2: время каста",
helpModules = {209, 65},
tasks = {
{
var = "playerCastStart",
desc = 'Создай глобальную переменную playerCastStart = select(4, UnitCastingInfo("player")) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerCastEnd",
desc = 'Создай глобальную переменную playerCastEnd = select(5, UnitCastingInfo("player")) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][212] = {
type = "commenttest",
title = "Тест 209-3: функция GetCastNameSafe",
helpModules = {209, 45, 65},
preloadVars = {
{var = "GetCastNameSafe", desc = "GetCastNameSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 209-3: функция GetCastNameSafe</h>
<t>Создай глобальную функцию <k>GetCastNameSafe(unit)</k>.</t>
<t>Если <k>unit</k> не является строкой, функция должна вернуть строку:</t>
<s>"нет"</s>
<t>Иначе функция должна сначала попробовать получить имя обычного каста через:</t>
<code>
UnitCastingInfo(unit)
</code>
<t>Если результат не является строкой или является пустой строкой, функция должна попробовать получить имя канального заклинания через:</t>
<code>
UnitChannelInfo(unit)
</code>
<t>Если и этот результат не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"нет"</s>
<t>Иначе функция должна вернуть имя заклинания.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetCastNameSafe(unit)
]=],
requireKeywords = {
"GetCastNameSafe",
"function",
"UnitCastingInfo",
"UnitChannelInfo",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetCastNameSafe) ~= "function" then
_G.checkError = "GetCastNameSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetCastNameSafe, "player")
if not ok1 then
_G.checkError = "Ошибка вызова GetCastNameSafe('player'): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для player функция должна вернуть строку"
return false
end
local ok2, result2 = pcall(_G.GetCastNameSafe, "ns_invalid_unit")
if not ok2 or result2 ~= "нет" then
_G.checkError = "Для несуществующего юнита функция должна вернуть 'нет'"
return false
end
return true
end,
}

ns_llua['lua'][213] = {
type = "commenttest",
title = "Тест 209-4: функция GetCastProgressSafe",
helpModules = {209, 45, 10, 65},
preloadVars = {
{var = "GetCastProgressSafe", desc = "GetCastProgressSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 209-4: функция GetCastProgressSafe</h>
<t>Создай глобальную функцию <k>GetCastProgressSafe(unit)</k>.</t>
<t>Если <k>unit</k> не является строкой, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить данные каста через:</t>
<code>
UnitCastingInfo(unit)
</code>
<t>Если обычного каста нет, функция должна попробовать:</t>
<code>
UnitChannelInfo(unit)
</code>
<t>Если имя каста не получено, функция должна вернуть <n>0</n>.</t>
<t>Если <k>startTime</k> или <k>endTime</k> не являются числами, функция должна вернуть <n>0</n>.</t>
<t>Если <k>endTime</k> меньше или равен <k>startTime</k>, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть процент прогресса от 0 до 100.</t>
<t>Формула:</t>
<code>
(GetTime() * 1000 - startTime) / (endTime - startTime) * 100
</code>
<t>Если результат меньше нуля, верни <n>0</n>.</t>
<t>Если результат больше 100, верни <n>100</n>.</t>
<t>Используй <k>math.floor</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetCastProgressSafe(unit)
]=],
requireKeywords = {
"GetCastProgressSafe",
"function",
"UnitCastingInfo",
"UnitChannelInfo",
"GetTime",
"math.floor",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetCastProgressSafe) ~= "function" then
_G.checkError = "GetCastProgressSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetCastProgressSafe, "player")
if not ok1 then
_G.checkError = "Ошибка вызова GetCastProgressSafe('player'): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < 0 or result1 > 100 then
_G.checkError = "Для player функция должна вернуть число от 0 до 100"
return false
end
local ok2, result2 = pcall(_G.GetCastProgressSafe, "ns_invalid_unit")
if not ok2 or result2 ~= 0 then
_G.checkError = "Для несуществующего юнита функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][214] = {
type = "commenttest",
title = "Тест 209-5: функция GetThreatStatusSafe",
helpModules = {209, 45, 65},
preloadVars = {
{var = "GetThreatStatusSafe", desc = "GetThreatStatusSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 209-5: функция GetThreatStatusSafe</h>
<t>Создай глобальную функцию <k>GetThreatStatusSafe(unit)</k>.</t>
<t>Если <k>unit</k> не является строкой, функция должна вернуть <n>-1</n>.</t>
<t>Иначе функция должна получить статус угрозы через:</t>
<code>
UnitThreatSituation(unit)
</code>
<t>Если результат не является числом или меньше нуля или больше 3, функция должна вернуть <n>-1</n>.</t>
<t>Иначе функция должна вернуть статус угрозы.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetThreatStatusSafe(unit)
]=],
requireKeywords = {
"GetThreatStatusSafe",
"function",
"UnitThreatSituation",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetThreatStatusSafe) ~= "function" then
_G.checkError = "GetThreatStatusSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetThreatStatusSafe, "player")
if not ok1 then
_G.checkError = "Ошибка вызова GetThreatStatusSafe('player'): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < -1 or result1 > 3 then
_G.checkError = "Для player функция должна вернуть число от -1 до 3"
return false
end
local ok2, result2 = pcall(_G.GetThreatStatusSafe, "ns_invalid_unit")
if not ok2 or result2 ~= -1 then
_G.checkError = "Для несуществующего юнита функция должна вернуть -1"
return false
end
return true
end,
}

ns_llua['lua'][215] = {
type = "info",
title = "Фреймы как объекты",
helpModules = {45, 44},
content = [=[
<h>Фреймы как объекты</h>
<t>С этого момента мы начинаем работать с интерфейсом. Основной строительный блок интерфейса WoW — фрейм.</t>
<t>Фрейм — это объект. У него есть методы.</t>
<h>CreateFrame</h>
<code>
MyFirstFrame = CreateFrame("Frame", "MyFirstFrame", UIParent)
</code>
<t>Аргументы:</t>
<c>"Frame"</c> — тип фрейма.
<c>"MyFirstFrame"</c> — глобальное имя.
<c>UIParent</c> — родитель.
<h>Глобальное имя</h>
<t>Если второй аргумент не <k>nil</k>, WoW создаст глобальную переменную с таким именем.</t>
<code>
print(type(MyFirstFrame))
</code>
<h>Методы через двоеточие</h>
<t>Методы объекта вызываются через двоеточие:</t>
<code>
MyFirstFrame:SetSize(200, 100)
MyFirstFrame:SetPoint("CENTER")
MyFirstFrame:Show()
MyFirstFrame:Hide()
</code>
<t>Запись через двоеточие примерно означает, что фрейм сам передаётся внутрь метода.</t>
<code>
MyFirstFrame.Show(MyFirstFrame)
</code>
<h>Показать и скрыть</h>
<code>
MyFirstFrame:Show()
</code>
<code>
MyFirstFrame:Hide()
</code>
<code>
print(MyFirstFrame:IsShown())
</code>
<w>Важно:</w> пока фрейму не заданы размер и позиция, он может быть невидим или находиться в неожиданном месте.
]=],
}

ns_llua['lua'][216] = {
type = "commenttest",
title = "Тест 215-1: первый фрейм",
helpModules = {215},
preloadVars = {
{var = "CourseTestFrame", desc = "CourseTestFrame очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 215-1: первый фрейм</h>
<t>Создай глобальный фрейм <k>CourseTestFrame</k>.</t>
<t>Используй:</t>
<code>
CourseTestFrame = CreateFrame("Frame", "CourseTestFrame", UIParent)
</code>
<t>Размер и позиция не нужны.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CourseTestFrame
]=],
requireKeywords = {
"CourseTestFrame",
"CreateFrame",
"Frame",
"UIParent",
},
checkCode = function()
_G.checkError = nil
local f = _G.CourseTestFrame
if not f then
_G.checkError = "CourseTestFrame не был создан"
return false
end
if type(f.Show) ~= "function" or type(f.Hide) ~= "function" or type(f.IsShown) ~= "function" then
_G.checkError = "CourseTestFrame не похож на фрейм"
return false
end
if f.GetName and f:GetName() ~= "CourseTestFrame" then
_G.checkError = "Фрейм должен иметь глобальное имя CourseTestFrame"
return false
end
return true
end,
}

ns_llua['lua'][217] = {
type = "commenttest",
title = "Тест 215-2: видимый фрейм",
helpModules = {215},
preloadVars = {
{var = "CourseFrameShown", desc = "CourseFrameShown очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 215-2: видимый фрейм</h>
<t>Создай глобальный фрейм <k>CourseFrameShown</k>.</t>
<t>Требования:</t>
<t>- тип фрейма: <s>"Frame"</s>;</t>
<t>- глобальное имя: <s>"CourseFrameShown"</s>;</t>
<t>- родитель: <k>UIParent</k>;</t>
<t>- размер: 180 на 120;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- фрейм должен быть показан через <k>Show()</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CourseFrameShown
]=],
requireKeywords = {
"CourseFrameShown",
"CreateFrame",
"Frame",
"UIParent",
"SetSize",
"SetPoint",
"Show",
},
checkCode = function()
_G.checkError = nil
local f = _G.CourseFrameShown
if not f or type(f.IsShown) ~= "function" then
_G.checkError = "CourseFrameShown не является фреймом"
return false
end
if not f:IsShown() then
_G.checkError = "Фрейм должен быть показан"
return false
end
if f:GetWidth() ~= 180 then
_G.checkError = "Ширина фрейма должна быть 180"
return false
end
if f:GetHeight() ~= 120 then
_G.checkError = "Высота фрейма должна быть 120"
return false
end
return true
end,
}

ns_llua['lua'][218] = {
type = "commenttest",
title = "Тест 215-3: скрытый фрейм",
helpModules = {215},
preloadVars = {
{var = "CourseFrameHidden", desc = "CourseFrameHidden очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 215-3: скрытый фрейм</h>
<t>Создай глобальный фрейм <k>CourseFrameHidden</k>.</t>
<t>Требования:</t>
<t>- тип фрейма: <s>"Frame"</s>;</t>
<t>- глобальное имя: <s>"CourseFrameHidden"</s>;</t>
<t>- родитель: <k>UIParent</k>;</t>
<t>- размер: 100 на 100;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- фрейм должен быть скрыт через <k>Hide()</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CourseFrameHidden
]=],
requireKeywords = {
"CourseFrameHidden",
"CreateFrame",
"Frame",
"UIParent",
"SetSize",
"SetPoint",
"Hide",
},
checkCode = function()
_G.checkError = nil
local f = _G.CourseFrameHidden
if not f or type(f.IsShown) ~= "function" then
_G.checkError = "CourseFrameHidden не является фреймом"
return false
end
if f:IsShown() then
_G.checkError = "Фрейм должен быть скрыт"
return false
end
return true
end,
}

ns_llua['lua'][219] = {
type = "commenttest",
title = "Тест 215-4: функция IsFrameShownSafe",
helpModules = {215, 45, 65},
preloadVars = {
{var = "IsFrameShownSafe", desc = "IsFrameShownSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 215-4: функция IsFrameShownSafe</h>
<t>Создай глобальную функцию <k>IsFrameShownSafe(frame)</k>.</t>
<t>Если <k>frame</k> не существует или у него нет метода <k>IsShown</k>, функция должна вернуть <k>false</k>.</t>
<t>Иначе функция должна вернуть результат:</t>
<code>
frame:IsShown()
</code>
<t>Результат должен быть именно boolean: <k>true</k> или <k>false</k>.</t>
<t>Используй приведение через <k>and true or false</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию IsFrameShownSafe(frame)
]=],
requireKeywords = {
"IsFrameShownSafe",
"function",
"IsShown",
"and",
"or",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.IsFrameShownSafe) ~= "function" then
_G.checkError = "IsFrameShownSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.IsFrameShownSafe, UIParent)
if not ok1 or result1 ~= true then
_G.checkError = "Для UIParent функция должна вернуть true"
return false
end
local ok2, result2 = pcall(_G.IsFrameShownSafe, nil)
if not ok2 or result2 ~= false then
_G.checkError = "Для nil функция должна вернуть false"
return false
end
local ok3, result3 = pcall(_G.IsFrameShownSafe, {})
if not ok3 or result3 ~= false then
_G.checkError = "Для пустой таблицы функция должна вернуть false"
return false
end
return true
end,
}

ns_llua['lua'][220] = {
type = "commenttest",
title = "Тест 215-5: функция GetFrameNameSafe",
helpModules = {215, 45, 65},
preloadVars = {
{var = "GetFrameNameSafe", desc = "GetFrameNameSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 215-5: функция GetFrameNameSafe</h>
<t>Создай глобальную функцию <k>GetFrameNameSafe(frame)</k>.</t>
<t>Если <k>frame</k> не существует или у него нет метода <k>GetName</k>, функция должна вернуть строку:</t>
<s>"anonymous"</s>
<t>Иначе функция должна получить имя через:</t>
<code>
frame:GetName()
</code>
<t>Если имя не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"anonymous"</s>
<t>Иначе функция должна вернуть имя фрейма.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetFrameNameSafe(frame)
]=],
requireKeywords = {
"GetFrameNameSafe",
"function",
"GetName",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetFrameNameSafe) ~= "function" then
_G.checkError = "GetFrameNameSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetFrameNameSafe, UIParent)
if not ok1 then
_G.checkError = "Ошибка вызова GetFrameNameSafe(UIParent): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для UIParent функция должна вернуть строку"
return false
end
local anon = CreateFrame("Frame", nil, UIParent)
local ok2, result2 = pcall(_G.GetFrameNameSafe, anon)
if not ok2 or result2 ~= "anonymous" then
_G.checkError = "Для анонимного фрейма функция должна вернуть 'anonymous'"
return false
end
local ok3, result3 = pcall(_G.GetFrameNameSafe, nil)
if not ok3 or result3 ~= "anonymous" then
_G.checkError = "Для nil функция должна вернуть 'anonymous'"
return false
end
return true
end,
}

ns_llua['lua'][221] = {
type = "info",
title = "Позиция, размер и перетаскивание",
helpModules = {215},
content = [=[
<h>Позиция, размер и перетаскивание</h>
<t>Чтобы фрейм было видно, ему нужны размер и точка крепления.</t>
<h>Размер</h>
<code>
MyFirstFrame:SetSize(220, 140)
</code>
<h>Позиция</h>
<code>
MyFirstFrame:SetPoint("CENTER")
</code>
<t>Более точный вариант:</t>
<code>
MyFirstFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -100)
</code>
<t>Это значит:</t>
<c>TOPLEFT</c> фрейма крепится к <c>TOPLEFT</c> родителя.
Смещение: <n>100</n> вправо и <n>-100</n> вниз.
<h>Слой отображения</h>
<code>
MyFirstFrame:SetFrameStrata("HIGH")
</code>
<t>Возможные значения:</t>
<c>"BACKGROUND"</c>
<c>"LOW"</c>
<c>"MEDIUM"</c>
<c>"HIGH"</c>
<c>"DIALOG"</c>
<c>"TOOLTIP"</c>
<h>Прозрачность и масштаб</h>
<code>
MyFirstFrame:SetAlpha(0.8)
MyFirstFrame:SetScale(1.1)
</code>
<h>Перетаскивание</h>
<code>
MyDragFrame = CreateFrame("Frame", "MyDragFrame", UIParent)
MyDragFrame:SetSize(160, 120)
MyDragFrame:SetPoint("CENTER")
MyDragFrame:EnableMouse(true)
MyDragFrame:SetMovable(true)
MyDragFrame:RegisterForDrag("LeftButton")
MyDragFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
MyDragFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
MyDragFrame:Show()
</code>
<w>Примечание:</w> без текстуры или фона фрейм может быть прозрачным, но он всё равно может ловить мышь, если включён <k>EnableMouse</k>.
]=],
}

ns_llua['lua'][222] = {
type = "commenttest",
title = "Тест 221-1: позиция CENTER",
helpModules = {221},
preloadVars = {
{var = "CoursePositionFrame", desc = "CoursePositionFrame очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 221-1: позиция CENTER</h>
<t>Создай глобальный фрейм <k>CoursePositionFrame</k>.</t>
<t>Требования:</t>
<t>- тип фрейма: <s>"Frame"</s>;</t>
<t>- глобальное имя: <s>"CoursePositionFrame"</s>;</t>
<t>- родитель: <k>UIParent</k>;</t>
<t>- размер: 160 на 120;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CoursePositionFrame
]=],
requireKeywords = {
"CoursePositionFrame",
"CreateFrame",
"Frame",
"UIParent",
"SetSize",
"SetPoint",
"CENTER",
},
checkCode = function()
_G.checkError = nil
local f = _G.CoursePositionFrame
if not f or type(f.GetPoint) ~= "function" then
_G.checkError = "CoursePositionFrame не является фреймом"
return false
end
if f:GetWidth() ~= 160 then
_G.checkError = "Ширина фрейма должна быть 160"
return false
end
if f:GetHeight() ~= 120 then
_G.checkError = "Высота фрейма должна быть 120"
return false
end
local point = f:GetPoint(1)
if point ~= "CENTER" then
_G.checkError = "Фрейм должен быть прикреплён через CENTER"
return false
end
return true
end,
}

ns_llua['lua'][223] = {
type = "commenttest",
title = "Тест 221-2: прозрачность и масштаб",
helpModules = {221},
preloadVars = {
{var = "CourseAlphaFrame", desc = "CourseAlphaFrame очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 221-2: прозрачность и масштаб</h>
<t>Создай глобальный фрейм <k>CourseAlphaFrame</k>.</t>
<t>Требования:</t>
<t>- тип фрейма: <s>"Frame"</s>;</t>
<t>- глобальное имя: <s>"CourseAlphaFrame"</s>;</t>
<t>- родитель: <k>UIParent</k>;</t>
<t>- размер: 100 на 100;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- прозрачность: <k>SetAlpha(0.5)</k>;</t>
<t>- масштаб: <k>SetScale(1)</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CourseAlphaFrame
]=],
requireKeywords = {
"CourseAlphaFrame",
"CreateFrame",
"Frame",
"UIParent",
"SetSize",
"SetPoint",
"SetAlpha",
"SetScale",
},
checkCode = function()
_G.checkError = nil
local f = _G.CourseAlphaFrame
if not f or type(f.GetAlpha) ~= "function" or type(f.GetScale) ~= "function" then
_G.checkError = "CourseAlphaFrame не является фреймом"
return false
end
local alpha = f:GetAlpha()
if type(alpha) ~= "number" or math.abs(alpha - 0.5) > 0.01 then
_G.checkError = "Alpha фрейма должен быть примерно 0.5"
return false
end
local scale = f:GetScale()
if type(scale) ~= "number" or math.abs(scale - 1) > 0.01 then
_G.checkError = "Scale фрейма должен быть примерно 1"
return false
end
return true
end,
}

ns_llua['lua'][224] = {
type = "commenttest",
title = "Тест 221-3: слой HIGH",
helpModules = {221},
preloadVars = {
{var = "CourseStrataFrame", desc = "CourseStrataFrame очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 221-3: слой HIGH</h>
<t>Создай глобальный фрейм <k>CourseStrataFrame</k>.</t>
<t>Требования:</t>
<t>- тип фрейма: <s>"Frame"</s>;</t>
<t>- глобальное имя: <s>"CourseStrataFrame"</s>;</t>
<t>- родитель: <k>UIParent</k>;</t>
<t>- размер: 80 на 80;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- слой: <k>SetFrameStrata("HIGH")</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CourseStrataFrame
]=],
requireKeywords = {
"CourseStrataFrame",
"CreateFrame",
"Frame",
"UIParent",
"SetSize",
"SetPoint",
"SetFrameStrata",
"HIGH",
},
checkCode = function()
_G.checkError = nil
local f = _G.CourseStrataFrame
if not f or type(f.GetFrameStrata) ~= "function" then
_G.checkError = "CourseStrataFrame не является фреймом"
return false
end
if f:GetFrameStrata() ~= "HIGH" then
_G.checkError = "Фрейм должен иметь слой HIGH"
return false
end
return true
end,
}

ns_llua['lua'][225] = {
type = "commenttest",
title = "Тест 221-4: перетаскиваемый фрейм",
helpModules = {221},
preloadVars = {
{var = "CourseDragFrame", desc = "CourseDragFrame очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 221-4: перетаскиваемый фрейм</h>
<t>Создай глобальный фрейм <k>CourseDragFrame</k>.</t>
<t>Требования:</t>
<t>- тип фрейма: <s>"Frame"</s>;</t>
<t>- глобальное имя: <s>"CourseDragFrame"</s>;</t>
<t>- родитель: <k>UIParent</k>;</t>
<t>- размер: 140 на 100;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- включи мышку через <k>EnableMouse(true)</k>;</t>
<t>- сделай фрейм перемещаемым через <k>SetMovable(true)</k>;</t>
<t>- зарегистрируй перетаскивание через <k>RegisterForDrag("LeftButton")</k>;</t>
<t>- назначь скрипт <k>OnDragStart</k>, чтобы он вызывал <k>self:StartMoving()</k>;</t>
<t>- назначь скрипт <k>OnDragStop</k>, чтобы он вызывал <k>self:StopMovingOrSizing()</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CourseDragFrame
]=],
requireKeywords = {
"CourseDragFrame",
"CreateFrame",
"Frame",
"UIParent",
"SetSize",
"SetPoint",
"EnableMouse",
"SetMovable",
"RegisterForDrag",
"SetScript",
"OnDragStart",
"OnDragStop",
"StartMoving",
"StopMovingOrSizing",
},
checkCode = function()
_G.checkError = nil
local f = _G.CourseDragFrame
if not f or type(f.GetScript) ~= "function" then
_G.checkError = "CourseDragFrame не является фреймом"
return false
end
if type(f:GetScript("OnDragStart")) ~= "function" then
_G.checkError = "Фрейм должен иметь обработчик OnDragStart"
return false
end
if type(f:GetScript("OnDragStop")) ~= "function" then
_G.checkError = "Фрейм должен иметь обработчик OnDragStop"
return false
end
return true
end,
}

ns_llua['lua'][226] = {
type = "commenttest",
title = "Тест 221-5: функция SetFrameSizeSafe",
helpModules = {221, 45, 65},
preloadVars = {
{var = "SetFrameSizeSafe", desc = "SetFrameSizeSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 221-5: функция SetFrameSizeSafe</h>
<t>Создай глобальную функцию <k>SetFrameSizeSafe(frame, width, height)</k>.</t>
<t>Если <k>frame</k> не существует или у него нет метода <k>SetSize</k>, функция ничего не должна делать.</t>
<t>Если <k>width</k> или <k>height</k> не являются числами, функция ничего не должна делать.</t>
<t>Если <k>width</k> или <k>height</k> меньше либо равны нулю, функция ничего не должна делать.</t>
<t>Иначе функция должна вызвать:</t>
<code>
frame:SetSize(width, height)
</code>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию SetFrameSizeSafe(frame, width, height)
]=],
requireKeywords = {
"SetFrameSizeSafe",
"function",
"SetSize",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.SetFrameSizeSafe) ~= "function" then
_G.checkError = "SetFrameSizeSafe не является глобальной функцией"
return false
end
local f = CreateFrame("Frame", nil, UIParent)
local ok1 = pcall(_G.SetFrameSizeSafe, f, 123, 45)
if not ok1 then
_G.checkError = "Ошибка вызова SetFrameSizeSafe с корректными данными"
return false
end
if f:GetWidth() ~= 123 or f:GetHeight() ~= 45 then
_G.checkError = "SetFrameSizeSafe должна изменить размер фрейма"
return false
end
local ok2 = pcall(_G.SetFrameSizeSafe, f, -5, 10)
if not ok2 then
_G.checkError = "Ошибка вызова SetFrameSizeSafe с отрицательной шириной"
return false
end
if f:GetWidth() ~= 123 or f:GetHeight() ~= 45 then
_G.checkError = "Некорректные данные не должны менять размер фрейма"
return false
end
local ok3 = pcall(_G.SetFrameSizeSafe, nil, 10, 10)
if not ok3 then
_G.checkError = "SetFrameSizeSafe не должна падать на nil"
return false
end
return true
end,
}

ns_llua['lua'][227] = {
type = "info",
title = "Текстуры и текст на фреймах",
helpModules = {215, 221},
content = [=[
<h>Текстуры и текст на фреймах</h>
<t>Сам по себе фрейм невидим. Чтобы что-то показать на нём, нужны текстуры и текстовые объекты.</t>
<h>CreateTexture</h>
<t>Метод <k>CreateTexture</k> создаёт текстуру внутри фрейма.</t>
<code>
MyIconFrame = CreateFrame("Frame", "MyIconFrame", UIParent)
MyIconFrame:SetSize(64, 64)
MyIconFrame:SetPoint("CENTER")
local tex = MyIconFrame:CreateTexture(nil, "ARTWORK")
tex:SetAllPoints(MyIconFrame)
tex:SetTexture("Interface\\Icons\\Spell_Frost_IceStorm")
</code>
<t>Аргументы <k>CreateTexture</k>:</t>
<c>1</c> — имя текстуры. Обычно <k>nil</k>.
<c>2</c> — слой: <s>BACKGROUND</s>, <s>BORDER</s>, <s>ARTWORK</s>, <s>OVERLAY</s>.
<h>SetAllPoints</h>
<t>Метод <k>SetAllPoints(parent)</k> растягивает текстуру на весь родительский фрейм.</t>
<code>
tex:SetAllPoints(MyIconFrame)
</code>
<t>Это то же самое, что прикрепить текстуру всеми четырьмя углами к фрейму.</t>
<h>CreateFontString</h>
<t>Текст создаётся методом <k>CreateFontString</k>.</t>
<code>
local text = MyIconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER")
text:SetText("Привет!")
</code>
<t>Третий аргумент — шаблон шрифта:</t>
<c>GameFontNormal</c> — обычный текст.
<c>GameFontNormalLarge</c> — крупный текст.
<c>GameFontHighlight</c> — белый текст.
<c>GameFontRed</c> — красный текст.
<h>Цвет текста</h>
<code>
text:SetTextColor(1, 1, 0, 1)
</code>
<t>Четыре числа: красный, зелёный, синий, прозрачность. Каждое от 0 до 1.</t>
<h>Выравнивание</h>
<code>
text:SetJustifyH("LEFT")
text:SetJustifyH("CENTER")
text:SetJustifyH("RIGHT")
</code>
<h>Размер шрифта</h>
<code>
text:SetFont("Fonts\\FRIZQT__.TTF", 16)
</code>
<t>Первый аргумент — файл шрифта, второй — размер.</t>
<w>Важно:</w> если шрифт не найден, текст может не отобразиться. Поэтому лучше использовать готовые шаблоны вроде <k>GameFontNormal</k>.
<h>Иконки из игры</h>
<t>Пути к иконкам начинаются с <s>Interface\Icons\</s>.</t>
<code>
tex:SetTexture("Interface\\Icons\\Spell_Frost_IceStorm")
tex:SetTexture("Interface\\Icons\\Inv_Sword_04")
</code>
<w>Обрати внимание:</w> в Lua-строке обратный слеш пишется как <k>\\</k>, потому что одинарный слеш имеет специальное значение.
<h>Полный пример</h>
<code>
CourseInfoFrame = CreateFrame("Frame", "CourseInfoFrame", UIParent)
CourseInfoFrame:SetSize(200, 200)
CourseInfoFrame:SetPoint("CENTER")
CourseInfoFrame:SetFrameStrata("HIGH")
local bg = CourseInfoFrame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(CourseInfoFrame)
bg:SetTexture(0.1, 0.1, 0.1, 0.8)
local icon = CourseInfoFrame:CreateTexture(nil, "ARTWORK")
icon:SetSize(64, 64)
icon:SetPoint("TOP", 0, -10)
icon:SetTexture("Interface\\Icons\\Spell_Frost_IceStorm")
local title = CourseInfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", icon, "BOTTOM", 0, -10)
title:SetText("Курс Lua")
title:SetTextColor(1, 0.84, 0, 1)
CourseInfoFrame:Show()
</code>
<h>Частые ошибки</h>
<w>Ошибка 1:</w> забыть <k>Show()</k> у фрейма.
<w>Ошибка 2:</w> перепутать слой. Текстура на слое <s>BACKGROUND</s> будет под текстом на слое <s>OVERLAY</s>.
<w>Ошибка 3:</w> написать путь к иконке с одинарными слешами.
<code>
tex:SetTexture("Interface\Icons\Icon")   -- ошибка
tex:SetTexture("Interface\\Icons\\Icon") -- правильно
</code>
]=],
}

ns_llua['lua'][228] = {
type = "commenttest",
title = "Тест 227-1: фрейм с иконкой",
helpModules = {227, 221, 215},
preloadVars = {
{var = "CourseIconFrame", desc = "CourseIconFrame очищается перед проверкой"},
},
reportVars = {"CourseIconFrame"},
instruction = [=[
<h>Тест 227-1: фрейм с иконкой</h>
<t>Создай глобальный фрейм <k>CourseIconFrame</k>.</t>
<t>Требования:</t>
<t>- тип: <s>Frame</s>;</t>
<t>- глобальное имя: <s>CourseIconFrame</s>;</t>
<t>- родитель: <k>UIParent</k>;</t>
<t>- размер: 64 на 64;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- внутри создай текстуру слоем <s>ARTWORK</s>;</t>
<t>- текстура должна быть растянута через <k>SetAllPoints</k>;</t>
<t>- установи текстуре путь: <s>Interface\Icons\Spell_Frost_IceStorm</s>;</t>
<t>- покажи фрейм через <k>Show()</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CourseIconFrame
]=],
requireKeywords = {
"CourseIconFrame",
"CreateFrame",
"Frame",
"UIParent",
"SetSize",
"SetPoint",
"CreateTexture",
"ARTWORK",
"SetAllPoints",
"SetTexture",
"Show",
},
checkCode = function()
local f = _G.CourseIconFrame
if not f then
    return false
end
if type(f.IsShown) ~= "function" then
    return false
end
if not f:IsShown() then
    return false
end
if f:GetWidth() ~= 64 or f:GetHeight() ~= 64 then
    return false
end
if not f.CreateTexture or type(f.CreateTexture) ~= "function" then
    return false
end
return true
end,
}

ns_llua['lua'][229] = {
type = "commenttest",
title = "Тест 227-2: фрейм с текстом",
helpModules = {227, 215, 7},
preloadVars = {
{var = "CourseTextFrame", desc = "CourseTextFrame очищается перед проверкой"},
},
reportVars = {"CourseTextFrame"},
instruction = [=[
<h>Тест 227-2: фрейм с текстом</h>
<t>Создай глобальный фрейм <k>CourseTextFrame</k>.</t>
<t>Требования:</t>
<t>- тип: <s>Frame</s>;</t>
<t>- глобальное имя: <s>CourseTextFrame</s>;</t>
<t>- родитель: <k>UIParent</k>;</t>
<t>- размер: 200 на 60;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- внутри создай FontString слоем <s>OVERLAY</s> с шаблоном <s>GameFontNormal</s>;</t>
<t>- установи текст: <s>Привет, Азерот!</s>;</t>
<t>- прикрепи текст через <k>SetPoint("CENTER")</k>;</t>
<t>- покажи фрейм через <k>Show()</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CourseTextFrame
]=],
requireKeywords = {
"CourseTextFrame",
"CreateFrame",
"Frame",
"UIParent",
"SetSize",
"SetPoint",
"CreateFontString",
"OVERLAY",
"GameFontNormal",
"SetText",
"Show",
},
checkCode = function()
local f = _G.CourseTextFrame
if not f then
    return false
end
if type(f.IsShown) ~= "function" then
    return false
end
if not f:IsShown() then
    return false
end
if f:GetWidth() ~= 200 or f:GetHeight() ~= 60 then
    return false
end
if type(f.CreateFontString) ~= "function" then
    return false
end
return true
end,
}

ns_llua['lua'][230] = {
type = "commenttest",
title = "Тест 227-3: функция CreateLabeledFrame",
helpModules = {227, 215, 45, 65},
preloadVars = {
{var = "CreateLabeledFrame", desc = "CreateLabeledFrame очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 227-3: функция CreateLabeledFrame</h>
<t>Создай глобальную функцию <k>CreateLabeledFrame(name, text)</k>.</t>
<t>Функция должна создать фрейм и вернуть его.</t>
<t>Требования:</t>
<t>- если <k>name</k> не строка или пустая строка, функция должна вернуть <k>nil</k>;</t>
<t>- если <k>text</k> не строка, используй пустую строку <s>""</s>;</t>
<t>- создай фрейм типа <s>Frame</s> с именем <k>name</k> и родителем <k>UIParent</k>;</t>
<t>- размер фрейма: 220 на 80;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- создай внутри FontString слоем <s>OVERLAY</s> с шаблоном <s>GameFontNormal</s>;</t>
<t>- установи тексту текст из аргумента;</t>
<t>- прикрепи текст через <k>SetPoint("CENTER")</k>;</t>
<t>- покажи фрейм;</t>
<t>- верни фрейм.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CreateLabeledFrame(name, text)
]=],
requireKeywords = {
"CreateLabeledFrame",
"function",
"CreateFrame",
"CreateFontString",
"SetText",
"SetPoint",
"Show",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CreateLabeledFrame) ~= "function" then
    _G.checkError = "CreateLabeledFrame не является глобальной функцией"
    return false
end
local ok1, f1 = pcall(_G.CreateLabeledFrame, "NS_Test_Labeled_1", "Текст")
if not ok1 then
    _G.checkError = "Ошибка вызова CreateLabeledFrame: " .. tostring(f1)
    return false
end
if not f1 or type(f1.IsShown) ~= "function" then
    _G.checkError = "Функция должна вернуть фрейм"
    return false
end
if not f1:IsShown() then
    _G.checkError = "Фрейм должен быть показан"
    return false
end
if f1:GetWidth() ~= 220 or f1:GetHeight() ~= 80 then
    _G.checkError = "Размер фрейма должен быть 220 на 80"
    return false
end
local ok2, f2 = pcall(_G.CreateLabeledFrame, "", "Текст")
if not ok2 or f2 ~= nil then
    _G.checkError = "Для пустого имени функция должна вернуть nil"
    return false
end
local ok3, f3 = pcall(_G.CreateLabeledFrame, 123, "Текст")
if not ok3 or f3 ~= nil then
    _G.checkError = "Для нестрокового имени функция должна вернуть nil"
    return false
end
local ok4, f4 = pcall(_G.CreateLabeledFrame, "NS_Test_Labeled_2", nil)
if not ok4 then
    _G.checkError = "Ошибка вызова CreateLabeledFrame с nil-текстом: " .. tostring(f4)
    return false
end
if not f4 or type(f4.IsShown) ~= "function" then
    _G.checkError = "Для nil-текста функция всё равно должна вернуть фрейм"
    return false
end
return true
end,
}

ns_llua['lua'][231] = {
type = "commenttest",
title = "Тест 227-4: функция SetFrameTextSafe",
helpModules = {227, 215, 45, 65, 21},
preloadVars = {
{var = "SetFrameTextSafe", desc = "SetFrameTextSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 227-4: функция SetFrameTextSafe</h>
<t>Создай глобальную функцию <k>SetFrameTextSafe(frame, text)</k>.</t>
<t>Функция должна безопасно установить текст на фрейм.</t>
<t>Требования:</t>
<t>- если <k>frame</k> не существует или у него нет метода <k>CreateFontString</k>, функция должна вернуть <k>false</k>;</t>
<t>- если <k>text</k> не строка, функция должна вернуть <k>false</k>;</t>
<t>- иначе создай FontString слоем <s>OVERLAY</s> с шаблоном <s>GameFontNormal</s>;</t>
<t>- прикрепи текст через <k>SetPoint("CENTER")</k>;</t>
<t>- установи текст через <k>SetText(text)</k>;</t>
<t>- верни <k>true</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию SetFrameTextSafe(frame, text)
]=],
requireKeywords = {
"SetFrameTextSafe",
"function",
"CreateFontString",
"OVERLAY",
"GameFontNormal",
"SetText",
"SetPoint",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.SetFrameTextSafe) ~= "function" then
    _G.checkError = "SetFrameTextSafe не является глобальной функцией"
    return false
end
local testFrame = CreateFrame("Frame", nil, UIParent)
testFrame:SetSize(150, 50)
local ok1, result1 = pcall(_G.SetFrameTextSafe, testFrame, "Проверка")
if not ok1 then
    _G.checkError = "Ошибка вызова SetFrameTextSafe: " .. tostring(result1)
    return false
end
if result1 ~= true then
    _G.checkError = "Для корректного фрейма функция должна вернуть true"
    return false
end
local ok2, result2 = pcall(_G.SetFrameTextSafe, nil, "Проверка")
if not ok2 or result2 ~= false then
    _G.checkError = "Для nil-фрейма функция должна вернуть false"
    return false
end
local ok3, result3 = pcall(_G.SetFrameTextSafe, testFrame, 123)
if not ok3 or result3 ~= false then
    _G.checkError = "Для нестрокового текста функция должна вернуть false"
    return false
end
local ok4, result4 = pcall(_G.SetFrameTextSafe, {}, "Проверка")
if not ok4 or result4 ~= false then
    _G.checkError = "Для пустой таблицы функция должна вернуть false"
    return false
end
return true
end,
}

ns_llua['lua'][232] = {
type = "commenttest",
title = "Тест 227-5: функция CreateIconFrameSafe",
helpModules = {227, 221, 215, 45, 65, 10, 17, 19},
preloadVars = {
{var = "CreateIconFrameSafe", desc = "CreateIconFrameSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 227-5: функция CreateIconFrameSafe</h>
<t>Создай глобальную функцию <k>CreateIconFrameSafe(parent, texturePath, size)</k>.</t>
<t>Функция должна безопасно создать фрейм с иконкой.</t>
<t>Требования:</t>
<t>- если <k>parent</k> не существует или у него нет метода <k>CreateFrame</k> как у фрейма, верни <k>nil</k>;</t>
<t>- если <k>texturePath</k> не строка или пустая строка, верни <k>nil</k>;</t>
<t>- если <k>size</k> не число, меньше 8 или больше 512, верни <k>nil</k>;</t>
<t>- иначе создай анонимный фрейм типа <s>Frame</s> с родителем <k>parent</k>;</t>
<t>- размер фрейма: <k>size</k> на <k>size</k>;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- создай текстуру слоем <s>ARTWORK</s>;</t>
<t>- растяни текстуру через <k>SetAllPoints</k>;</t>
<t>- установи текстуру через <k>SetTexture(texturePath)</k>;</t>
<t>- покажи фрейм;</t>
<t>- верни фрейм.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CreateIconFrameSafe(parent, texturePath, size)
]=],
requireKeywords = {
"CreateIconFrameSafe",
"function",
"CreateFrame",
"CreateTexture",
"SetAllPoints",
"SetTexture",
"SetSize",
"SetPoint",
"Show",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CreateIconFrameSafe) ~= "function" then
    _G.checkError = "CreateIconFrameSafe не является глобальной функцией"
    return false
end
local ok1, f1 = pcall(_G.CreateIconFrameSafe, UIParent, "Interface\\Icons\\Spell_Frost_IceStorm", 48)
if not ok1 then
    _G.checkError = "Ошибка вызова CreateIconFrameSafe: " .. tostring(f1)
    return false
end
if not f1 or type(f1.IsShown) ~= "function" then
    _G.checkError = "Для корректных данных функция должна вернуть фрейм"
    return false
end
if not f1:IsShown() then
    _G.checkError = "Созданный фрейм должен быть показан"
    return false
end
if f1:GetWidth() ~= 48 or f1:GetHeight() ~= 48 then
    _G.checkError = "Размер фрейма должен совпадать с аргументом size"
    return false
end
local ok2, f2 = pcall(_G.CreateIconFrameSafe, nil, "Interface\\Icons\\Spell_Frost_IceStorm", 48)
if not ok2 or f2 ~= nil then
    _G.checkError = "Для nil-родителя функция должна вернуть nil"
    return false
end
local ok3, f3 = pcall(_G.CreateIconFrameSafe, UIParent, "", 48)
if not ok3 or f3 ~= nil then
    _G.checkError = "Для пустой строки текстуры функция должна вернуть nil"
    return false
end
local ok4, f4 = pcall(_G.CreateIconFrameSafe, UIParent, "Interface\\Icons\\Spell_Frost_IceStorm", 4)
if not ok4 or f4 ~= nil then
    _G.checkError = "Для размера меньше 8 функция должна вернуть nil"
    return false
end
local ok5, f5 = pcall(_G.CreateIconFrameSafe, UIParent, "Interface\\Icons\\Spell_Frost_IceStorm", 1000)
if not ok5 or f5 ~= nil then
    _G.checkError = "Для размера больше 512 функция должна вернуть nil"
    return false
end
local ok6, f6 = pcall(_G.CreateIconFrameSafe, UIParent, "Interface\\Icons\\Spell_Frost_IceStorm", "big")
if not ok6 or f6 ~= nil then
    _G.checkError = "Для нечислового размера функция должна вернуть nil"
    return false
end
return true
end,
}






























ns_llua['lua'][233] = {
type = "info",
title = "Кнопки и обработчики кликов",
helpModules = {215, 221, 227},
content = [=[
<h>Кнопки и обработчики кликов</h>
<t>Кнопка — это специальный тип фрейма, который реагирует на клики мыши.</t>
<h>Создание кнопки</h>
<code>
CourseButton = CreateFrame("Button", "CourseButton", UIParent)
CourseButton:SetSize(120, 40)
CourseButton:SetPoint("CENTER")
</code>
<t>Обрати внимание: тип фрейма — <s>"Button"</s>, а не <s>"Frame"</s>.</t>
<h>Текст кнопки через FontString</h>
<t>У кнопки без шаблона нет встроенного текста. Его нужно создавать вручную:</t>
<code>
local fs = CourseButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fs:SetAllPoints(CourseButton)
fs:SetText("Нажми меня")
</code>
<h>Шаблон UIPanelButtonTemplate</h>
<t>WoW предоставляет готовые шаблоны. С шаблоном <s>"UIPanelButtonTemplate"</s> кнопка получает стандартный внешний вид и метод <k>SetText</k>:</t>
<code>
CourseStyledButton = CreateFrame("Button", "CourseStyledButton", UIParent, "UIPanelButtonTemplate")
CourseStyledButton:SetSize(120, 40)
CourseStyledButton:SetPoint("CENTER")
CourseStyledButton:SetText("Готово")
</code>
<w>Примечание:</w> в WoW 3.3.5 <k>SetText</k> работает для кнопок, созданных с шаблоном <s>"UIPanelButtonTemplate"</s>. Для кнопок без шаблона нужно создавать FontString вручную.
<h>Обработчик клика</h>
<code>
CourseButton:SetScript("OnClick", function(self, button)
    print("Клик! Кнопка мыши: " .. tostring(button))
end)
</code>
<t>Аргументы обработчика:</t>
<c>self</c> — сама кнопка.
<c>button</c> — какая кнопка мыши нажата: <s>"LeftButton"</s>, <s>"RightButton"</s> и т.д.
<h>Enable и Disable</h>
<code>
CourseButton:Enable()
CourseButton:Disable()
</code>
<t>Отключённая кнопка не реагирует на клики.</t>
<h>Проверка состояния</h>
<code>
if CourseButton:IsEnabled() then
    print("Кнопка включена")
else
    print("Кнопка отключена")
end
</code>
<w>Важно:</w> в WoW 3.3.5 <k>IsEnabled()</k> возвращает <k>1</k> или <k>nil</k>, а не <k>true</k>/<k>false</k>. Но в условии <k>if</k> это работает одинаково, потому что <k>1</k> — истина, а <k>nil</k> — ложь.
<h>Безопасный обработчик</h>
<code>
CourseSafeButton:SetScript("OnClick", function(self)
    if not self:IsEnabled() then return end
    print("Действие выполнено")
end)
</code>
<h>Частые ошибки</h>
<w>Ошибка 1:</w> забыть <k>Show()</k> у кнопки.
<w>Ошибка 2:</w> использовать <k>SetText</k> на кнопке без шаблона.
<w>Ошибка 3:</w> сравнивать <k>IsEnabled()</k> с <k>true</k> через <k>==</k>.
<code>
-- неправильно
if CourseButton:IsEnabled() == true then
-- правильно
if CourseButton:IsEnabled() then
</code>
]=],
}

ns_llua['lua'][234] = {
type = "commenttest",
title = "Тест 233-1: кнопка с обработчиком",
helpModules = {233, 215, 221},
preloadVars = {
{var = "CourseClickButton", desc = "CourseClickButton очищается перед проверкой"},
{var = "courseClickCount", desc = "courseClickCount очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
"courseClickCount",
},
instruction = [=[
<h>Тест 233-1: кнопка с обработчиком</h>
<t>Создай глобальную кнопку <k>CourseClickButton</k>.</t>
<t>Требования:</t>
<t>- тип фрейма: <s>"Button"</s>;</t>
<t>- глобальное имя: <s>"CourseClickButton"</s>;</t>
<t>- родитель: <k>UIParent</k>;</t>
<t>- размер: 120 на 40;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- создай глобальную переменную <k>courseClickCount</k> со значением <n>0</n>;</t>
<t>- назначь обработчик <k>OnClick</k>, который увеличивает <k>courseClickCount</k> на 1.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную кнопку CourseClickButton
]=],
requireKeywords = {
"CourseClickButton",
"CreateFrame",
"Button",
"UIParent",
"SetSize",
"SetPoint",
"SetScript",
"OnClick",
"courseClickCount",
},
checkCode = function()
_G.checkError = nil
local f = _G.CourseClickButton
if not f then
    _G.checkError = "CourseClickButton не был создан"
    return false
end
if type(f.GetScript) ~= "function" then
    _G.checkError = "CourseClickButton не похож на кнопку"
    return false
end
if f:GetWidth() ~= 120 or f:GetHeight() ~= 40 then
    _G.checkError = "Размер кнопки должен быть 120 на 40"
    return false
end
local script = f:GetScript("OnClick")
if type(script) ~= "function" then
    _G.checkError = "У кнопки должен быть обработчик OnClick"
    return false
end
if _G.courseClickCount ~= 0 then
    _G.checkError = "courseClickCount должен быть 0 до клика"
    return false
end
-- Вызываем обработчик вручную, чтобы проверить логику
local ok, err = pcall(script, f, "LeftButton")
if not ok then
    _G.checkError = "Ошибка при вызове OnClick: " .. tostring(err)
    return false
end
if _G.courseClickCount ~= 1 then
    _G.checkError = "После одного клика courseClickCount должен быть 1"
    return false
end
-- Второй клик
local ok2, err2 = pcall(script, f, "LeftButton")
if not ok2 then
    _G.checkError = "Ошибка при втором вызове OnClick: " .. tostring(err2)
    return false
end
if _G.courseClickCount ~= 2 then
    _G.checkError = "После двух кликов courseClickCount должен быть 2"
    return false
end
return true
end,
}

ns_llua['lua'][235] = {
type = "commenttest",
title = "Тест 233-2: кнопка-переключатель",
helpModules = {233, 215, 221, 17},
preloadVars = {
{var = "CourseToggleTarget", desc = "CourseToggleTarget очищается перед проверкой"},
{var = "CourseToggleButton", desc = "CourseToggleButton очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 233-2: кнопка-переключатель</h>
<t>Создай два глобальных объекта:</t>
<t>1. Фрейм <k>CourseToggleTarget</k>:</t>
<t>- тип: <s>"Frame"</s>, родитель: <k>UIParent</k>;</t>
<t>- размер: 100 на 100;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- фрейм должен быть показан через <k>Show()</k>.</t>
<t>2. Кнопку <k>CourseToggleButton</k>:</t>
<t>- тип: <s>"Button"</s>, родитель: <k>UIParent</k>;</t>
<t>- размер: 100 на 30;</t>
<t>- позиция: <k>SetPoint("CENTER", UIParent, "CENTER", 0, -100)</k>;</t>
<t>- обработчик <k>OnClick</k>, который переключает видимость <k>CourseToggleTarget</k>:</t>
<t>если фрейм показан — скрыть через <k>Hide()</k>, иначе — показать через <k>Show()</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай CourseToggleTarget и CourseToggleButton
]=],
requireKeywords = {
"CourseToggleTarget",
"CourseToggleButton",
"CreateFrame",
"Frame",
"Button",
"UIParent",
"SetSize",
"SetPoint",
"Show",
"SetScript",
"OnClick",
"IsShown",
"Hide",
},
checkCode = function()
_G.checkError = nil
local target = _G.CourseToggleTarget
local button = _G.CourseToggleButton
if not target then
    _G.checkError = "CourseToggleTarget не был создан"
    return false
end
if not button then
    _G.checkError = "CourseToggleButton не был создан"
    return false
end
if type(target.IsShown) ~= "function" then
    _G.checkError = "CourseToggleTarget не похож на фрейм"
    return false
end
if type(button.GetScript) ~= "function" then
    _G.checkError = "CourseToggleButton не похож на кнопку"
    return false
end
if not target:IsShown() then
    _G.checkError = "CourseToggleTarget должен быть показан изначально"
    return false
end
local script = button:GetScript("OnClick")
if type(script) ~= "function" then
    _G.checkError = "У кнопки должен быть обработчик OnClick"
    return false
end
-- Первый клик: фрейм должен скрыться
local ok1, err1 = pcall(script, button, "LeftButton")
if not ok1 then
    _G.checkError = "Ошибка при первом вызове OnClick: " .. tostring(err1)
    return false
end
if target:IsShown() then
    _G.checkError = "После первого клика фрейм должен быть скрыт"
    return false
end
-- Второй клик: фрейм должен показаться
local ok2, err2 = pcall(script, button, "LeftButton")
if not ok2 then
    _G.checkError = "Ошибка при втором вызове OnClick: " .. tostring(err2)
    return false
end
if not target:IsShown() then
    _G.checkError = "После второго клика фрейм должен быть показан"
    return false
end
return true
end,
}

ns_llua['lua'][236] = {
type = "commenttest",
title = "Тест 233-3: функция CreateClickCounter",
helpModules = {233, 215, 45, 44},
preloadVars = {
{var = "CreateClickCounter", desc = "CreateClickCounter очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 233-3: функция CreateClickCounter</h>
<t>Создай глобальную функцию <k>CreateClickCounter(name)</k>.</t>
<t>Аргумент:</t>
<c>name</c> — строка с глобальным именем кнопки.
<t>Функция должна:</t>
<t>- если <k>name</k> не является строкой или является пустой строкой, вернуть <k>nil</k>;</t>
<t>- создать кнопку типа <s>"Button"</s> с глобальным именем <k>name</k> и родителем <k>UIParent</k>;</t>
<t>- задать размер 100 на 30;</t>
<t>- задать позицию <k>SetPoint("CENTER")</k>;</t>
<t>- создать таблицу-счётчик с полем <k>count</k> равным <n>0</n>;</t>
<t>- назначить обработчик <k>OnClick</k>, который увеличивает <k>count</k> на 1;</t>
<t>- вернуть таблицу с полями:</t>
<c>frame</c> — созданная кнопка.
<c>count</c> — текущее количество кликов.
<c>GetCount</c> — функция, которая возвращает текущее количество кликов.
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CreateClickCounter(name)
]=],
requireKeywords = {
"CreateClickCounter",
"function",
"CreateFrame",
"Button",
"SetScript",
"OnClick",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CreateClickCounter) ~= "function" then
    _G.checkError = "CreateClickCounter не является глобальной функцией"
    return false
end
local ok1, result1 = pcall(_G.CreateClickCounter, "NS_Test_Counter_1")
if not ok1 then
    _G.checkError = "Ошибка вызова CreateClickCounter: " .. tostring(result1)
    return false
end
if type(result1) ~= "table" then
    _G.checkError = "Функция должна вернуть таблицу"
    return false
end
if result1.count ~= 0 then
    _G.checkError = "Начальное значение count должно быть 0"
    return false
end
if not result1.frame then
    _G.checkError = "В таблице должно быть поле frame"
    return false
end
if type(result1.GetCount) ~= "function" then
    _G.checkError = "В таблице должна быть функция GetCount"
    return false
end
if result1.GetCount() ~= 0 then
    _G.checkError = "GetCount должна вернуть 0 до кликов"
    return false
end
-- Вызываем OnClick вручную
local script = result1.frame:GetScript("OnClick")
if type(script) ~= "function" then
    _G.checkError = "У кнопки должен быть обработчик OnClick"
    return false
end
local ok2, err2 = pcall(script, result1.frame, "LeftButton")
if not ok2 then
    _G.checkError = "Ошибка при вызове OnClick: " .. tostring(err2)
    return false
end
if result1.count ~= 1 then
    _G.checkError = "После одного клика count должен быть 1"
    return false
end
if result1.GetCount() ~= 1 then
    _G.checkError = "GetCount должна вернуть 1 после одного клика"
    return false
end
-- Проверяем пустое имя
local ok3, result3 = pcall(_G.CreateClickCounter, "")
if not ok3 or result3 ~= nil then
    _G.checkError = "Для пустого имени функция должна вернуть nil"
    return false
end
-- Проверяем нестроковое имя
local ok4, result4 = pcall(_G.CreateClickCounter, 123)
if not ok4 or result4 ~= nil then
    _G.checkError = "Для нестрокового имени функция должна вернуть nil"
    return false
end
return true
end,
}

ns_llua['lua'][237] = {
type = "commenttest",
title = "Тест 233-4: функция SetButtonEnabledSafe",
helpModules = {233, 45, 65, 21},
preloadVars = {
{var = "SetButtonEnabledSafe", desc = "SetButtonEnabledSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 233-4: функция SetButtonEnabledSafe</h>
<t>Создай глобальную функцию <k>SetButtonEnabledSafe(button, enabled)</k>.</t>
<t>Функция должна безопасно включить или выключить кнопку.</t>
<t>Требования:</t>
<t>- если <k>button</k> не существует или у него нет метода <k>Enable</k> или <k>Disable</k>, функция должна вернуть <k>false</k>;</t>
<t>- если <k>enabled</k> является истинным значением, вызови <k>button:Enable()</k> и верни <k>true</k>;</t>
<t>- если <k>enabled</k> является ложным значением, вызови <k>button:Disable()</k> и верни <k>true</k>;</t>
<t>- используй <k>type</k> для проверки наличия методов.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию SetButtonEnabledSafe(button, enabled)
]=],
requireKeywords = {
"SetButtonEnabledSafe",
"function",
"Enable",
"Disable",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.SetButtonEnabledSafe) ~= "function" then
    _G.checkError = "SetButtonEnabledSafe не является глобальной функцией"
    return false
end
-- Создаём тестовую кнопку
local testButton = CreateFrame("Button", nil, UIParent)
testButton:SetSize(80, 30)
-- Тест 1: выключить кнопку
local ok1, result1 = pcall(_G.SetButtonEnabledSafe, testButton, false)
if not ok1 then
    _G.checkError = "Ошибка вызова SetButtonEnabledSafe(button, false): " .. tostring(result1)
    return false
end
if result1 ~= true then
    _G.checkError = "Для корректной кнопки и false функция должна вернуть true"
    return false
end
if testButton:IsEnabled() then
    _G.checkError = "После Disable кнопка должна быть отключена"
    return false
end
-- Тест 2: включить кнопку
local ok2, result2 = pcall(_G.SetButtonEnabledSafe, testButton, true)
if not ok2 then
    _G.checkError = "Ошибка вызова SetButtonEnabledSafe(button, true): " .. tostring(result2)
    return false
end
if result2 ~= true then
    _G.checkError = "Для корректной кнопки и true функция должна вернуть true"
    return false
end
if not testButton:IsEnabled() then
    _G.checkError = "После Enable кнопка должна быть включена"
    return false
end
-- Тест 3: nil вместо кнопки
local ok3, result3 = pcall(_G.SetButtonEnabledSafe, nil, true)
if not ok3 or result3 ~= false then
    _G.checkError = "Для nil-кнопки функция должна вернуть false"
    return false
end
-- Тест 4: пустая таблица вместо кнопки
local ok4, result4 = pcall(_G.SetButtonEnabledSafe, {}, true)
if not ok4 or result4 ~= false then
    _G.checkError = "Для пустой таблицы функция должна вернуть false"
    return false
end
return true
end,
}

ns_llua['lua'][238] = {
type = "commenttest",
title = "Тест 233-5: функция ToggleFrameVisibility",
helpModules = {233, 215, 45, 65, 17},
preloadVars = {
{var = "ToggleFrameVisibility", desc = "ToggleFrameVisibility очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 233-5: функция ToggleFrameVisibility</h>
<t>Создай глобальную функцию <k>ToggleFrameVisibility(frame)</k>.</t>
<t>Функция должна переключить видимость фрейма.</t>
<t>Требования:</t>
<t>- если <k>frame</k> не существует или у него нет метода <k>IsShown</k>, функция должна вернуть <k>nil</k>;</t>
<t>- если фрейм показан, вызови <k>frame:Hide()</k> и верни <k>false</k>;</t>
<t>- если фрейм скрыт, вызови <k>frame:Show()</k> и верни <k>true</k>;</t>
<t>- используй <k>IsShown()</k> для проверки видимости.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию ToggleFrameVisibility(frame)
]=],
requireKeywords = {
"ToggleFrameVisibility",
"function",
"IsShown",
"Show",
"Hide",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.ToggleFrameVisibility) ~= "function" then
    _G.checkError = "ToggleFrameVisibility не является глобальной функцией"
    return false
end
-- Создаём тестовый фрейм
local testFrame = CreateFrame("Frame", nil, UIParent)
testFrame:SetSize(100, 100)
testFrame:SetPoint("CENTER")
testFrame:Show()
-- Тест 1: фрейм показан -> должен скрыться
local ok1, result1 = pcall(_G.ToggleFrameVisibility, testFrame)
if not ok1 then
    _G.checkError = "Ошибка вызова ToggleFrameVisibility: " .. tostring(result1)
    return false
end
if result1 ~= false then
    _G.checkError = "Для показанного фрейма функция должна вернуть false"
    return false
end
if testFrame:IsShown() then
    _G.checkError = "После ToggleFrameVisibility показанный фрейм должен быть скрыт"
    return false
end
-- Тест 2: фрейм скрыт -> должен показаться
local ok2, result2 = pcall(_G.ToggleFrameVisibility, testFrame)
if not ok2 then
    _G.checkError = "Ошибка второго вызова ToggleFrameVisibility: " .. tostring(result2)
    return false
end
if result2 ~= true then
    _G.checkError = "Для скрытого фрейма функция должна вернуть true"
    return false
end
if not testFrame:IsShown() then
    _G.checkError = "После ToggleFrameVisibility скрытый фрейм должен быть показан"
    return false
end
-- Тест 3: nil вместо фрейма
local ok3, result3 = pcall(_G.ToggleFrameVisibility, nil)
if not ok3 or result3 ~= nil then
    _G.checkError = "Для nil-фрейма функция должна вернуть nil"
    return false
end
-- Тест 4: пустая таблица вместо фрейма
local ok4, result4 = pcall(_G.ToggleFrameVisibility, {})
if not ok4 or result4 ~= nil then
    _G.checkError = "Для пустой таблицы функция должна вернуть nil"
    return false
end
return true
end,
}

ns_llua['lua'][239] = {
type = "info",
title = "События: RegisterEvent и OnEvent",
helpModules = {215, 227, 233},
content = [=[
<h>События: RegisterEvent и OnEvent</h>
<t>До сих пор наш код выполнялся один раз. Чтобы аддон реагировал на действия игрока — смену цели, получение урона, вход в игру — нужны события.</t>
<h>Как работают события</h>
<t>WoW генерирует события автоматически. Например:</t>
<c>PLAYER_LOGIN</c> — игрок вошёл в мир.
<c>PLAYER_TARGET_CHANGED</c> — сменилась цель.
<c>UNIT_HEALTH</c> — изменилось здоровье юнита.
<c>PLAYER_REGEN_ENABLED</c> — игрок вышел из боя.
<c>PLAYER_REGEN_DISABLED</c> — игрок вошёл в бой.
<c>BAG_UPDATE</c> — содержимое сумок изменилось.
<h>Регистрация события</h>
<t>Чтобы фрейм получал события, нужно зарегистрировать их методом <k>RegisterEvent</k>:</t>
<code>
MyEventFrame = CreateFrame("Frame", nil, UIParent)
MyEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
</code>
<h>Обработчик OnEvent</h>
<t>Когда событие происходит, WoW вызывает скрипт <k>OnEvent</k>:</t>
<code>
MyEventFrame:SetScript("OnEvent", function(self, event)
    print("Событие: " .. event)
end)
</code>
<t>Аргументы обработчика:</t>
<c>self</c> — фрейм, на который пришло событие.
<c>event</c> — строка с именем события.
<c>...</c> — дополнительные аргументы события (зависят от события).
<h>Несколько событий на одном фрейме</h>
<code>
MyMultiFrame = CreateFrame("Frame", nil, UIParent)
MyMultiFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
MyMultiFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
MyMultiFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_TARGET_CHANGED" then
        print("Цель изменилась")
    elseif event == "PLAYER_REGEN_DISABLED" then
        print("Вошёл в бой")
    end
end)
</code>
<h>Событие UNIT_HEALTH</h>
<t>Некоторые события требуют указания юнита через <k>RegisterUnitEvent</k>:</t>
<code>
MyHealthFrame = CreateFrame("Frame", nil, UIParent)
MyHealthFrame:RegisterUnitEvent("UNIT_HEALTH", "player")
MyHealthFrame:SetScript("OnEvent", function(self, event, unit)
    if unit == "player" then
        print("HP: " .. (UnitHealth("player") or 0))
    end
end)
</code>
<w>Важно:</w> в WoW 3.3.5 вместо RegisterUnitEvent можно использовать RegisterEvent, но тогда придётся вручную проверять аргумент unit.
<h>PLAYER_LOGIN — точка входа</h>
<t>Событие <c>PLAYER_LOGIN</c> срабатывает, когда игрок полностью вошёл в мир. Это лучшее место для инициализации аддона:</t>
<code>
MyInitFrame = CreateFrame("Frame", nil, UIParent)
MyInitFrame:RegisterEvent("PLAYER_LOGIN")
MyInitFrame:SetScript("OnEvent", function(self, event)
    print("Добро пожаловать, " .. (UnitName("player") or "Неизвестный"))
end)
</code>
<h>Частые ошибки</h>
<w>Ошибка 1:</w> забыть зарегистрировать событие перед назначением OnEvent.
<code>
-- неправильно: событие не зарегистрировано
MyFrame:SetScript("OnEvent", function(self, event) end)
-- правильно: сначала регистрируем
MyFrame:RegisterEvent("PLAYER_LOGIN")
MyFrame:SetScript("OnEvent", function(self, event) end)
</code>
<w>Ошибка 2:</w> сравнивать event с числом вместо строки.
<code>
-- неправильно
if event == 1 then
-- правильно
if event == "PLAYER_TARGET_CHANGED" then
</code>
<w>Ошибка 3:</w> ожидать, что OnEvent вызовется без RegisterEvent. Событие придёт только на зарегистрированные события.
]=],
}

ns_llua['lua'][240] = {
type = "vartest",
title = "Тест 239-1: строки событий",
helpModules = {239},
tasks = {
{
var = "eventLogin",
desc = 'Создай глобальную переменную eventLogin = "PLAYER_LOGIN"',
check = function(value)
return value == "PLAYER_LOGIN"
end,
},
{
var = "eventTarget",
desc = 'Создай глобальную переменную eventTarget = "PLAYER_TARGET_CHANGED"',
check = function(value)
return value == "PLAYER_TARGET_CHANGED"
end,
},
{
var = "eventCombatStart",
desc = 'Создай глобальную переменную eventCombatStart = "PLAYER_REGEN_DISABLED"',
check = function(value)
return value == "PLAYER_REGEN_DISABLED"
end,
},
},
}

ns_llua['lua'][241] = {
type = "commenttest",
title = "Тест 239-2: фрейм с зарегистрированным событием",
helpModules = {239, 215},
preloadVars = {
{var = "CourseEventFrame", desc = "CourseEventFrame очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 239-2: фрейм с зарегистрированным событием</h>
<t>Создай глобальный фрейм <k>CourseEventFrame</k>.</t>
<t>Требования:</t>
<t>- тип: <s>"Frame"</s>, родитель: <k>UIParent</k>;</t>
<t>- зарегистрируй событие <s>"PLAYER_TARGET_CHANGED"</s> через <k>RegisterEvent</k>;</t>
<t>- назначь скрипт <k>OnEvent</k>, который ничего не делает (пустая функция).</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CourseEventFrame
]=],
requireKeywords = {
"CourseEventFrame",
"CreateFrame",
"Frame",
"UIParent",
"RegisterEvent",
"PLAYER_TARGET_CHANGED",
"SetScript",
"OnEvent",
},
checkCode = function()
_G.checkError = nil
local f = _G.CourseEventFrame
if not f then
    _G.checkError = "CourseEventFrame не был создан"
    return false
end
if type(f.GetScript) ~= "function" then
    _G.checkError = "CourseEventFrame не похож на фрейм"
    return false
end
local script = f:GetScript("OnEvent")
if type(script) ~= "function" then
    _G.checkError = "У фрейма должен быть обработчик OnEvent"
    return false
end
if type(f.RegisterEvent) ~= "function" then
    _G.checkError = "У фрейма должен быть метод RegisterEvent"
    return false
end
return true
end,
}

ns_llua['lua'][242] = {
type = "commenttest",
title = "Тест 239-3: обработчик с двумя событиями",
helpModules = {239, 215, 19},
preloadVars = {
{var = "CourseMultiEventFrame", desc = "CourseMultiEventFrame очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 239-3: обработчик с двумя событиями</h>
<t>Создай глобальный фрейм <k>CourseMultiEventFrame</k>.</t>
<t>Требования:</t>
<t>- тип: <s>"Frame"</s>, родитель: <k>UIParent</k>;</t>
<t>- зарегистрируй два события:</t>
<c>"PLAYER_REGEN_DISABLED"</c>
<c>"PLAYER_REGEN_ENABLED"</c>
<t>- назначь скрипт <k>OnEvent</k>, который:</t>
<t>если event равен <s>"PLAYER_REGEN_DISABLED"</s>, записывает в глобальную переменную <k>combatStateLog</k> строку <s>"in"</s>;</t>
<t>если event равен <s>"PLAYER_REGEN_ENABLED"</s>, записывает в глобальную переменную <k>combatStateLog</k> строку <s>"out"</s>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CourseMultiEventFrame
]=],
requireKeywords = {
"CourseMultiEventFrame",
"CreateFrame",
"Frame",
"UIParent",
"RegisterEvent",
"PLAYER_REGEN_DISABLED",
"PLAYER_REGEN_ENABLED",
"SetScript",
"OnEvent",
"combatStateLog",
},
checkCode = function()
_G.checkError = nil
local f = _G.CourseMultiEventFrame
if not f then
    _G.checkError = "CourseMultiEventFrame не был создан"
    return false
end
local script = f:GetScript("OnEvent")
if type(script) ~= "function" then
    _G.checkError = "У фрейма должен быть обработчик OnEvent"
    return false
end
-- Вызываем обработчик вручную, чтобы проверить логику
_G.combatStateLog = nil
local ok1, err1 = pcall(script, f, "PLAYER_REGEN_DISABLED")
if not ok1 then
    _G.checkError = "Ошибка при вызове OnEvent с PLAYER_REGEN_DISABLED: " .. tostring(err1)
    return false
end
if _G.combatStateLog ~= "in" then
    _G.checkError = "После PLAYER_REGEN_DISABLED combatStateLog должен быть 'in'"
    return false
end
_G.combatStateLog = nil
local ok2, err2 = pcall(script, f, "PLAYER_REGEN_ENABLED")
if not ok2 then
    _G.checkError = "Ошибка при вызове OnEvent с PLAYER_REGEN_ENABLED: " .. tostring(err2)
    return false
end
if _G.combatStateLog ~= "out" then
    _G.checkError = "После PLAYER_REGEN_ENABLED combatStateLog должен быть 'out'"
    return false
end
return true
end,
}

ns_llua['lua'][243] = {
type = "commenttest",
title = "Тест 239-4: функция CreateEventLogger",
helpModules = {239, 215, 45, 65},
preloadVars = {
{var = "CreateEventLogger", desc = "CreateEventLogger очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 239-4: функция CreateEventLogger</h>
<t>Создай глобальную функцию <k>CreateEventLogger(eventName)</k>.</t>
<t>Требования:</t>
<t>- если <k>eventName</k> не является строкой или является пустой строкой, верни <k>nil</k>;</t>
<t>- иначе создай анонимный фрейм типа <s>"Frame"</s> с родителем <k>UIParent</k>;</t>
<t>- зарегистрируй событие через <k>RegisterEvent(eventName)</k>;</t>
<t>- создай таблицу с полями:</t>
<c>frame</c> — созданный фрейм.
<c>count</c> — число, изначально 0.
<c>lastEvent</c> — строка, изначально пустая строка.
<t>- назначь обработчик OnEvent, который увеличивает <k>count</k> на 1 и записывает <k>event</k> в <k>lastEvent</k>;</t>
<t>- верни таблицу.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CreateEventLogger(eventName)
]=],
requireKeywords = {
"CreateEventLogger",
"function",
"CreateFrame",
"Frame",
"UIParent",
"RegisterEvent",
"SetScript",
"OnEvent",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CreateEventLogger) ~= "function" then
    _G.checkError = "CreateEventLogger не является глобальной функцией"
    return false
end
-- Тест 1: корректное событие
local ok1, logger1 = pcall(_G.CreateEventLogger, "PLAYER_TARGET_CHANGED")
if not ok1 then
    _G.checkError = "Ошибка вызова CreateEventLogger: " .. tostring(logger1)
    return false
end
if type(logger1) ~= "table" then
    _G.checkError = "Функция должна вернуть таблицу"
    return false
end
if not logger1.frame then
    _G.checkError = "В таблице должно быть поле frame"
    return false
end
if logger1.count ~= 0 then
    _G.checkError = "Начальное значение count должно быть 0"
    return false
end
if logger1.lastEvent ~= "" then
    _G.checkError = "Начальное значение lastEvent должно быть пустой строкой"
    return false
end
-- Вызываем OnEvent вручную
local script = logger1.frame:GetScript("OnEvent")
if type(script) ~= "function" then
    _G.checkError = "У фрейма должен быть обработчик OnEvent"
    return false
end
local ok2, err2 = pcall(script, logger1.frame, "PLAYER_TARGET_CHANGED")
if not ok2 then
    _G.checkError = "Ошибка при вызове OnEvent: " .. tostring(err2)
    return false
end
if logger1.count ~= 1 then
    _G.checkError = "После одного события count должен быть 1"
    return false
end
if logger1.lastEvent ~= "PLAYER_TARGET_CHANGED" then
    _G.checkError = "lastEvent должен содержать имя события"
    return false
end
-- Тест 2: пустая строка
local ok3, logger2 = pcall(_G.CreateEventLogger, "")
if not ok3 or logger2 ~= nil then
    _G.checkError = "Для пустой строки функция должна вернуть nil"
    return false
end
-- Тест 3: не строка
local ok4, logger3 = pcall(_G.CreateEventLogger, 123)
if not ok4 or logger3 ~= nil then
    _G.checkError = "Для нестрокового аргумента функция должна вернуть nil"
    return false
end
return true
end,
}

ns_llua['lua'][244] = {
type = "commenttest",
title = "Тест 239-5: функция CreateHealthWatcher",
helpModules = {239, 215, 83, 65, 45},
preloadVars = {
{var = "CreateHealthWatcher", desc = "CreateHealthWatcher очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 239-5: функция CreateHealthWatcher</h>
<t>Создай глобальную функцию <k>CreateHealthWatcher(unit)</k>.</t>
<t>Требования:</t>
<t>- если <k>unit</k> не является строкой или является пустой строкой, верни <k>nil</k>;</t>
<t>- иначе создай анонимный фрейм типа <s>"Frame"</s> с родителем <k>UIParent</k>;</t>
<t>- зарегистрируй событие <s>"UNIT_HEALTH"</s> через <k>RegisterEvent</k>;</t>
<t>- создай таблицу с полями:</t>
<c>frame</c> — созданный фрейм.
<c>unit</c> — строка unit.
<c>lastHP</c> — число, изначально 0.
<c>updateCount</c> — число, изначально 0.
<t>- назначь обработчик OnEvent, который:</t>
<t>если аргумент unit события совпадает с сохранённым unit, увеличивает <k>updateCount</k> на 1 и записывает текущее здоровье через <k>UnitHealth(unit) or 0</k> в <k>lastHP</k>;</t>
<t>- верни таблицу.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CreateHealthWatcher(unit)
]=],
requireKeywords = {
"CreateHealthWatcher",
"function",
"CreateFrame",
"Frame",
"UIParent",
"RegisterEvent",
"UNIT_HEALTH",
"SetScript",
"OnEvent",
"UnitHealth",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CreateHealthWatcher) ~= "function" then
    _G.checkError = "CreateHealthWatcher не является глобальной функцией"
    return false
end
-- Тест 1: корректный unit
local ok1, watcher = pcall(_G.CreateHealthWatcher, "player")
if not ok1 then
    _G.checkError = "Ошибка вызова CreateHealthWatcher: " .. tostring(watcher)
    return false
end
if type(watcher) ~= "table" then
    _G.checkError = "Функция должна вернуть таблицу"
    return false
end
if not watcher.frame then
    _G.checkError = "В таблице должно быть поле frame"
    return false
end
if watcher.unit ~= "player" then
    _G.checkError = "Поле unit должно быть 'player'"
    return false
end
if watcher.lastHP ~= 0 then
    _G.checkError = "Начальное значение lastHP должно быть 0"
    return false
end
if watcher.updateCount ~= 0 then
    _G.checkError = "Начальное значение updateCount должно быть 0"
    return false
end
-- Вызываем OnEvent вручную с правильным unit
local script = watcher.frame:GetScript("OnEvent")
if type(script) ~= "function" then
    _G.checkError = "У фрейма должен быть обработчик OnEvent"
    return false
end
local ok2, err2 = pcall(script, watcher.frame, "UNIT_HEALTH", "player")
if not ok2 then
    _G.checkError = "Ошибка при вызове OnEvent: " .. tostring(err2)
    return false
end
if watcher.updateCount ~= 1 then
    _G.checkError = "После одного события updateCount должен быть 1"
    return false
end
-- Вызываем с другим unit — не должно меняться
local ok3, err3 = pcall(script, watcher.frame, "UNIT_HEALTH", "target")
if not ok3 then
    _G.checkError = "Ошибка при вызове OnEvent с target: " .. tostring(err3)
    return false
end
if watcher.updateCount ~= 1 then
    _G.checkError = "Для другого unit updateCount не должен меняться"
    return false
end
-- Тест 2: пустая строка
local ok4, watcher2 = pcall(_G.CreateHealthWatcher, "")
if not ok4 or watcher2 ~= nil then
    _G.checkError = "Для пустой строки функция должна вернуть nil"
    return false
end
-- Тест 3: не строка
local ok5, watcher3 = pcall(_G.CreateHealthWatcher, 123)
if not ok5 or watcher3 ~= nil then
    _G.checkError = "Для нестрокового аргумента функция должна вернуть nil"
    return false
end
return true
end,
}

ns_llua['lua'][245] = {
type = "info",
title = "OnUpdate: таймеры и ручная имитация анимаций",
helpModules = {215, 221, 227},
content = [=[
<h>OnUpdate: таймеры и ручная имитация анимаций</h>
<w>Важно:</w> в WoW 3.3.5 нет готовых анимаций и системы AnimationGroup. Всё, что связано с движением, мерцанием, плавным появлением и исчезновением, делается вручную через <k>OnUpdate</k>.
<h>Что такое OnUpdate</h>
<t>Скрипт <k>OnUpdate</k> вызывается каждый кадр для фрейма. Это примерно 30-60 раз в секунду, в зависимости от FPS.</t>
<code>
MyTimerFrame = CreateFrame("Frame", nil, UIParent)
MyTimerFrame:SetScript("OnUpdate", function(self, elapsed)
    -- этот код выполняется каждый кадр
end)
</code>
<t>Аргументы обработчика:</t>
<c>self</c> — сам фрейм.
<c>elapsed</c> — время в секундах, прошедшее с последнего кадра. Обычно очень маленькое число, например 0.016.
<h>Накопление времени</h>
<t>Чтобы отсчитать нужное количество секунд, накапливают <k>elapsed</k> в переменной.</t>
<code>
MyTimerFrame.elapsed = 0
MyTimerFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed >= 5 then
        print("Прошло 5 секунд")
        self:SetScript("OnUpdate", nil)
    end
end)
</code>
<t>Когда время вышло, скрипт снимают через <k>SetScript("OnUpdate", nil)</k>, чтобы он больше не выполнялся.</t>
<h>Почему elapsed, а не GetTime</h>
<t><k>elapsed</k> даёт точное время между кадрами. Это удобно для плавных анимаций, потому что скорость анимации не зависит от FPS.</t>
<code>
-- неправильно: привязка к FPS
self.alpha = self.alpha + 0.01
-- правильно: привязка ко времени
self.alpha = self.alpha + elapsed * speed
</code>
<h>Одноразовый таймер</h>
<code>
function CreateOneShotTimer(seconds, callback)
    local f = CreateFrame("Frame", nil, UIParent)
    f.elapsed = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= seconds then
            self:SetScript("OnUpdate", nil)
            if type(callback) == "function" then
                callback()
            end
        end
    end)
    return f
end
</code>
<h>Повторяющийся таймер</h>
<code>
function CreateRepeatingTimer(seconds, callback)
    local f = CreateFrame("Frame", nil, UIParent)
    f.elapsed = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= seconds then
            self.elapsed = self.elapsed - seconds
            if type(callback) == "function" then
                callback()
            end
        end
    end)
    return f
end
</code>
<t>Здесь вместо снятия скрипта мы вычитаем прошедшее время, чтобы следующий интервал начался с остатка.</t>
<h>Ручная имитация анимации: плавное появление</h>
<code>
function CreateFadeIn(frame, duration)
    frame:SetAlpha(0)
    frame.elapsed = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        local progress = self.elapsed / duration
        if progress >= 1 then
            progress = 1
            self:SetScript("OnUpdate", nil)
        end
        self:SetAlpha(progress)
    end)
end
</code>
<h>Ручная имитация анимации: плавное исчезновение</h>
<code>
function CreateFadeOut(frame, duration)
    frame:SetAlpha(1)
    frame.elapsed = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        local progress = self.elapsed / duration
        if progress >= 1 then
            progress = 1
            self:SetScript("OnUpdate", nil)
        end
        self:SetAlpha(1 - progress)
    end)
end
</code>
<h>Ручная имитация анимации: мерцание</h>
<code>
function CreateBlink(frame, interval)
    frame.elapsed = 0
    frame.visible = true
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= interval then
            self.elapsed = self.elapsed - interval
            self.visible = not self.visible
            if self.visible then
                self:Show()
            else
                self:Hide()
            end
        end
    end)
end
</code>
<h>Ручная имитация анимации: пульсация масштаба</h>
<code>
function CreatePulse(frame, speed)
    frame.elapsed = 0
    frame.growing = true
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        local scale = self:GetScale()
        if self.growing then
            scale = scale + elapsed * speed
            if scale >= 1.2 then
                scale = 1.2
                self.growing = false
            end
        else
            scale = scale - elapsed * speed
            if scale <= 1.0 then
                scale = 1.0
                self.growing = true
            end
        end
        self:SetScale(scale)
    end)
end
</code>
<h>Ручная имитация анимации: обратный отсчёт</h>
<code>
function CreateCountdownDisplay(frame, seconds)
    frame.remaining = seconds
    frame.elapsed = 0
    local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fs:SetPoint("CENTER")
    fs:SetText(tostring(seconds))
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= 1 then
            self.elapsed = self.elapsed - 1
            self.remaining = self.remaining - 1
            if self.remaining <= 0 then
                fs:SetText("Готово!")
                self:SetScript("OnUpdate", nil)
            else
                fs:SetText(tostring(self.remaining))
            end
        end
    end)
end
</code>
<h>Частые ошибки</h>
<w>Ошибка 1:</w> забыть снять OnUpdate, когда анимация закончилась. Фрейм будет продолжать выполняться каждый кадр и тратить ресурсы.
<code>
-- неправильно: OnUpdate работает бесконечно
frame:SetScript("OnUpdate", function(self, elapsed)
    self:SetAlpha(self:GetAlpha() - 0.01)
end)
-- правильно: снимаем после завершения
frame:SetScript("OnUpdate", function(self, elapsed)
    local alpha = self:GetAlpha() - elapsed
    if alpha <= 0 then
        self:SetAlpha(0)
        self:SetScript("OnUpdate", nil)
    else
        self:SetAlpha(alpha)
    end
end)
</code>
<w>Ошибка 2:</w> не привязывать скорость к <k>elapsed</k>. Анимация будет зависеть от FPS.
<w>Ошибка 3:</w> использовать <k>GetTime()</k> внутри OnUpdate вместо накопления <k>elapsed</k>. Это работает, но менее точно и менее удобно для пауз.
]=],
}

ns_llua['lua'][246] = {
type = "vartest",
title = "Тест 245-1: базовые понятия OnUpdate",
helpModules = {245},
tasks = {
{
var = "onUpdateArgName",
desc = 'Создай глобальную переменную onUpdateArgName = "elapsed"',
check = function(value)
return value == "elapsed"
end,
},
{
var = "onUpdateStopMethod",
desc = 'Создай глобальную переменную onUpdateStopMethod = "SetScript"',
check = function(value)
return value == "SetScript"
end,
},
{
var = "onUpdateStopValue",
desc = 'Создай глобальную переменную onUpdateStopValue = nil',
check = function(value)
return value == nil
end,
},
},
}

ns_llua['lua'][247] = {
type = "commenttest",
title = "Тест 245-2: функция CreateOneShotTimer",
helpModules = {245, 215, 45},
preloadVars = {
{var = "CreateOneShotTimer", desc = "CreateOneShotTimer очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
{var = "testTimerFired", desc = "testTimerFired очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 245-2: функция CreateOneShotTimer</h>
<t>Создай глобальную функцию <k>CreateOneShotTimer(seconds, callback)</k>.</t>
<t>Требования:</t>
<t>- если <k>seconds</k> не является числом или меньше либо равно нуля, функция должна вернуть <k>nil</k>;</t>
<t>- иначе создай анонимный фрейм типа <s>"Frame"</s> с родителем <k>UIParent</k>;</t>
<t>- создай поле <k>elapsed</k> со значением <n>0</n>;</t>
<t>- назначь скрипт <k>OnUpdate</k>, который:</t>
<t>накапливает <k>elapsed</k>;</t>
<t>когда накопленное время больше или равно <k>seconds</k>, снимает скрипт через <k>SetScript("OnUpdate", nil)</k> и вызывает <k>callback</k>, если это функция;</t>
<t>- верни фрейм.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CreateOneShotTimer(seconds, callback)
]=],
requireKeywords = {
"CreateOneShotTimer",
"function",
"CreateFrame",
"Frame",
"UIParent",
"SetScript",
"OnUpdate",
"elapsed",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CreateOneShotTimer) ~= "function" then
    _G.checkError = "CreateOneShotTimer не является глобальной функцией"
    return false
end
-- Тест 1: некорректные секунды
local ok1, result1 = pcall(_G.CreateOneShotTimer, -1, nil)
if not ok1 or result1 ~= nil then
    _G.checkError = "Для отрицательных секунд функция должна вернуть nil"
    return false
end
local ok2, result2 = pcall(_G.CreateOneShotTimer, "bad", nil)
if not ok2 or result2 ~= nil then
    _G.checkError = "Для нечисловых секунд функция должна вернуть nil"
    return false
end
-- Тест 2: корректный вызов
_G.testTimerFired = false
local ok3, timerFrame = pcall(_G.CreateOneShotTimer, 0.01, function()
    _G.testTimerFired = true
end)
if not ok3 then
    _G.checkError = "Ошибка вызова CreateOneShotTimer: " .. tostring(timerFrame)
    return false
end
if not timerFrame or type(timerFrame.SetScript) ~= "function" then
    _G.checkError = "Функция должна вернуть фрейм"
    return false
end
if timerFrame.elapsed ~= 0 then
    _G.checkError = "Поле elapsed должно быть 0"
    return false
end
local script = timerFrame:GetScript("OnUpdate")
if type(script) ~= "function" then
    _G.checkError = "У фрейма должен быть обработчик OnUpdate"
    return false
end
-- Вызываем OnUpdate вручную с большим elapsed, чтобы сработал таймер
local ok4, err4 = pcall(script, timerFrame, 1)
if not ok4 then
    _G.checkError = "Ошибка при вызове OnUpdate: " .. tostring(err4)
    return false
end
if _G.testTimerFired ~= true then
    _G.checkError = "Callback должен быть вызван после истечения времени"
    return false
end
-- После срабатывания OnUpdate должен быть снят
local scriptAfter = timerFrame:GetScript("OnUpdate")
if scriptAfter ~= nil then
    _G.checkError = "После срабатывания таймера OnUpdate должен быть снят"
    return false
end
return true
end,
}

ns_llua['lua'][248] = {
type = "commenttest",
title = "Тест 245-3: функция CreateBlinkAnimation",
helpModules = {245, 215, 45},
preloadVars = {
{var = "CreateBlinkAnimation", desc = "CreateBlinkAnimation очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 245-3: функция CreateBlinkAnimation</h>
<t>Создай глобальную функцию <k>CreateBlinkAnimation(frame, interval)</k>.</t>
<t>Требования:</t>
<t>- если <k>frame</k> не существует или у него нет метода <k>Show</k> или <k>Hide</k>, функция должна вернуть <k>nil</k>;</t>
<t>- если <k>interval</k> не является числом или меньше либо равно нуля, функция должна вернуть <k>nil</k>;</t>
<t>- иначе создай поле <k>elapsed</k> со значением <n>0</n> на фрейме;</t>
<t>- создай поле <k>visible</k> со значением <k>true</k> на фрейме;</t>
<t>- назначь скрипт <k>OnUpdate</k>, который:</t>
<t>накапливает <k>elapsed</k>;</t>
<t>когда накопленное время больше или равно <k>interval</k>, вычитает <k>interval</k> из <k>elapsed</k>, переключает <k>visible</k> и вызывает <k>Show()</k> или <k>Hide()</k>;</t>
<t>- верни фрейм.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CreateBlinkAnimation(frame, interval)
]=],
requireKeywords = {
"CreateBlinkAnimation",
"function",
"Show",
"Hide",
"SetScript",
"OnUpdate",
"elapsed",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CreateBlinkAnimation) ~= "function" then
    _G.checkError = "CreateBlinkAnimation не является глобальной функцией"
    return false
end
-- Тест 1: некорректные аргументы
local ok1, result1 = pcall(_G.CreateBlinkAnimation, nil, 1)
if not ok1 or result1 ~= nil then
    _G.checkError = "Для nil-фрейма функция должна вернуть nil"
    return false
end
local testFrame = CreateFrame("Frame", nil, UIParent)
local ok2, result2 = pcall(_G.CreateBlinkAnimation, testFrame, -1)
if not ok2 or result2 ~= nil then
    _G.checkError = "Для отрицательного interval функция должна вернуть nil"
    return false
end
-- Тест 2: корректный вызов
local ok3, result3 = pcall(_G.CreateBlinkAnimation, testFrame, 0.5)
if not ok3 then
    _G.checkError = "Ошибка вызова CreateBlinkAnimation: " .. tostring(result3)
    return false
end
if not result3 or type(result3.Show) ~= "function" then
    _G.checkError = "Функция должна вернуть фрейм"
    return false
end
if result3.elapsed ~= 0 then
    _G.checkError = "Поле elapsed должно быть 0"
    return false
end
if result3.visible ~= true then
    _G.checkError = "Поле visible должно быть true"
    return false
end
local script = result3:GetScript("OnUpdate")
if type(script) ~= "function" then
    _G.checkError = "У фрейма должен быть обработчик OnUpdate"
    return false
end
-- Вызываем OnUpdate вручную, чтобы проверить переключение
result3:Show()
local ok4, err4 = pcall(script, result3, 1)
if not ok4 then
    _G.checkError = "Ошибка при вызове OnUpdate: " .. tostring(err4)
    return false
end
if result3.visible ~= false then
    _G.checkError = "После первого интервала visible должен быть false"
    return false
end
if result3:IsShown() then
    _G.checkError = "После первого интервала фрейм должен быть скрыт"
    return false
end
-- Второй вызов должен вернуть видимость
local ok5, err5 = pcall(script, result3, 1)
if not ok5 then
    _G.checkError = "Ошибка при втором вызове OnUpdate: " .. tostring(err5)
    return false
end
if result3.visible ~= true then
    _G.checkError = "После второго интервала visible должен быть true"
    return false
end
if not result3:IsShown() then
    _G.checkError = "После второго интервала фрейм должен быть показан"
    return false
end
return true
end,
}

ns_llua['lua'][249] = {
type = "commenttest",
title = "Тест 245-4: функция CreateFadeOutAnimation",
helpModules = {245, 215, 45, 10},
preloadVars = {
{var = "CreateFadeOutAnimation", desc = "CreateFadeOutAnimation очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 245-4: функция CreateFadeOutAnimation</h>
<t>Создай глобальную функцию <k>CreateFadeOutAnimation(frame, duration)</k>.</t>
<t>Требования:</t>
<t>- если <k>frame</k> не существует или у него нет метода <k>SetAlpha</k>, функция должна вернуть <k>nil</k>;</t>
<t>- если <k>duration</k> не является числом или меньше либо равно нуля, функция должна вернуть <k>nil</k>;</t>
<t>- иначе установи начальную прозрачность <k>SetAlpha(1)</k>;</t>
<t>- создай поле <k>elapsed</k> со значением <n>0</n> на фрейме;</t>
<t>- назначь скрипт <k>OnUpdate</k>, который:</t>
<t>накапливает <k>elapsed</k>;</t>
<t>вычисляет прогресс как <k>elapsed / duration</k>;</t>
<t>если прогресс больше или равен 1, устанавливает <k>SetAlpha(0)</k> и снимает скрипт;</t>
<t>иначе устанавливает <k>SetAlpha(1 - progress)</k>;</t>
<t>- верни фрейм.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CreateFadeOutAnimation(frame, duration)
]=],
requireKeywords = {
"CreateFadeOutAnimation",
"function",
"SetAlpha",
"SetScript",
"OnUpdate",
"elapsed",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CreateFadeOutAnimation) ~= "function" then
    _G.checkError = "CreateFadeOutAnimation не является глобальной функцией"
    return false
end
-- Тест 1: некорректные аргументы
local ok1, result1 = pcall(_G.CreateFadeOutAnimation, nil, 1)
if not ok1 or result1 ~= nil then
    _G.checkError = "Для nil-фрейма функция должна вернуть nil"
    return false
end
local testFrame = CreateFrame("Frame", nil, UIParent)
local ok2, result2 = pcall(_G.CreateFadeOutAnimation, testFrame, -1)
if not ok2 or result2 ~= nil then
    _G.checkError = "Для отрицательного duration функция должна вернуть nil"
    return false
end
-- Тест 2: корректный вызов
local ok3, result3 = pcall(_G.CreateFadeOutAnimation, testFrame, 2)
if not ok3 then
    _G.checkError = "Ошибка вызова CreateFadeOutAnimation: " .. tostring(result3)
    return false
end
if not result3 or type(result3.SetAlpha) ~= "function" then
    _G.checkError = "Функция должна вернуть фрейм"
    return false
end
if result3.elapsed ~= 0 then
    _G.checkError = "Поле elapsed должно быть 0"
    return false
end
local alpha = result3:GetAlpha()
if type(alpha) ~= "number" or math.abs(alpha - 1) > 0.01 then
    _G.checkError = "Начальная прозрачность должна быть 1"
    return false
end
local script = result3:GetScript("OnUpdate")
if type(script) ~= "function" then
    _G.checkError = "У фрейма должен быть обработчик OnUpdate"
    return false
end
-- Вызываем OnUpdate вручную с половиной duration
local ok4, err4 = pcall(script, result3, 1)
if not ok4 then
    _G.checkError = "Ошибка при вызове OnUpdate: " .. tostring(err4)
    return false
end
local alphaMid = result3:GetAlpha()
if type(alphaMid) ~= "number" or alphaMid > 0.6 or alphaMid < 0.4 then
    _G.checkError = "После половины duration прозрачность должна быть около 0.5"
    return false
end
-- Вызываем OnUpdate с оставшимся временем
local ok5, err5 = pcall(script, result3, 2)
if not ok5 then
    _G.checkError = "Ошибка при втором вызове OnUpdate: " .. tostring(err5)
    return false
end
local alphaEnd = result3:GetAlpha()
if type(alphaEnd) ~= "number" or alphaEnd > 0.01 then
    _G.checkError = "После завершения прозрачность должна быть 0"
    return false
end
-- После завершения OnUpdate должен быть снят
local scriptAfter = result3:GetScript("OnUpdate")
if scriptAfter ~= nil then
    _G.checkError = "После завершения анимации OnUpdate должен быть снят"
    return false
end
return true
end,
}

ns_llua['lua'][250] = {
type = "commenttest",
title = "Тест 245-5: функция CreateCountdownDisplay",
helpModules = {245, 215, 227, 45, 10},
preloadVars = {
{var = "CreateCountdownDisplay", desc = "CreateCountdownDisplay очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 245-5: функция CreateCountdownDisplay</h>
<t>Создай глобальную функцию <k>CreateCountdownDisplay(frame, seconds)</k>.</t>
<t>Требования:</t>
<t>- если <k>frame</k> не существует или у него нет метода <k>CreateFontString</k>, функция должна вернуть <k>nil</k>;</t>
<t>- если <k>seconds</k> не является целым числом или меньше либо равно нуля, функция должна вернуть <k>nil</k>;</t>
<t>- иначе создай FontString слоем <s>"OVERLAY"</s> с шаблоном <s>"GameFontNormalLarge"</s>;</t>
<t>- прикрепи текст через <k>SetPoint("CENTER")</k>;</t>
<t>- установи начальный текст как строку с числом <k>seconds</k>;</t>
<t>- создай поле <k>remaining</k> со значением <k>seconds</k> на фрейме;</t>
<t>- создай поле <k>elapsed</k> со значением <n>0</n> на фрейме;</t>
<t>- назначь скрипт <k>OnUpdate</k>, который:</t>
<t>накапливает <k>elapsed</k>;</t>
<t>когда накопленное время больше или равно 1, вычитает 1 из <k>elapsed</k> и уменьшает <k>remaining</k> на 1;</t>
<t>если <k>remaining</k> меньше или равно нуля, устанавливает текст <s>"Готово!"</s> и снимает скрипт;</t>
<t>иначе устанавливает текст как строку с числом <k>remaining</k>;</t>
<t>- верни фрейм.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CreateCountdownDisplay(frame, seconds)
]=],
requireKeywords = {
"CreateCountdownDisplay",
"function",
"CreateFontString",
"OVERLAY",
"GameFontNormalLarge",
"SetPoint",
"SetText",
"SetScript",
"OnUpdate",
"elapsed",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CreateCountdownDisplay) ~= "function" then
    _G.checkError = "CreateCountdownDisplay не является глобальной функцией"
    return false
end
-- Тест 1: некорректные аргументы
local ok1, result1 = pcall(_G.CreateCountdownDisplay, nil, 5)
if not ok1 or result1 ~= nil then
    _G.checkError = "Для nil-фрейма функция должна вернуть nil"
    return false
end
local testFrame = CreateFrame("Frame", nil, UIParent)
testFrame:SetSize(200, 100)
local ok2, result2 = pcall(_G.CreateCountdownDisplay, testFrame, -1)
if not ok2 or result2 ~= nil then
    _G.checkError = "Для отрицательного seconds функция должна вернуть nil"
    return false
end
local ok3, result3 = pcall(_G.CreateCountdownDisplay, testFrame, 1.5)
if not ok3 or result3 ~= nil then
    _G.checkError = "Для дробного seconds функция должна вернуть nil"
    return false
end
-- Тест 2: корректный вызов
local ok4, result4 = pcall(_G.CreateCountdownDisplay, testFrame, 3)
if not ok4 then
    _G.checkError = "Ошибка вызова CreateCountdownDisplay: " .. tostring(result4)
    return false
end
if not result4 or type(result4.CreateFontString) ~= "function" then
    _G.checkError = "Функция должна вернуть фрейм"
    return false
end
if result4.remaining ~= 3 then
    _G.checkError = "Поле remaining должно быть 3"
    return false
end
if result4.elapsed ~= 0 then
    _G.checkError = "Поле elapsed должно быть 0"
    return false
end
local script = result4:GetScript("OnUpdate")
if type(script) ~= "function" then
    _G.checkError = "У фрейма должен быть обработчик OnUpdate"
    return false
end
-- Вызываем OnUpdate вручную, чтобы проверить отсчёт
local ok5, err5 = pcall(script, result4, 1)
if not ok5 then
    _G.checkError = "Ошибка при вызове OnUpdate: " .. tostring(err5)
    return false
end
if result4.remaining ~= 2 then
    _G.checkError = "После первой секунды remaining должен быть 2"
    return false
end
local ok6, err6 = pcall(script, result4, 1)
if not ok6 then
    _G.checkError = "Ошибка при втором вызове OnUpdate: " .. tostring(err6)
    return false
end
if result4.remaining ~= 1 then
    _G.checkError = "После второй секунды remaining должен быть 1"
    return false
end
local ok7, err7 = pcall(script, result4, 1)
if not ok7 then
    _G.checkError = "Ошибка при третьем вызове OnUpdate: " .. tostring(err7)
    return false
end
if result4.remaining ~= 0 then
    _G.checkError = "После третьей секунды remaining должен быть 0"
    return false
end
-- После завершения OnUpdate должен быть снят
local scriptAfter = result4:GetScript("OnUpdate")
if scriptAfter ~= nil then
    _G.checkError = "После завершения отсчёта OnUpdate должен быть снят"
    return false
end
return true
end,
}

ns_llua['lua'][251] = {
type = "info",
title = "Книга заклинаний и HasSpell",
helpModules = {191, 65, 45},
content = [=[
<h>Книга заклинаний и HasSpell</h>
<t>Книга заклинаний — это список всех заклинаний, которые персонаж выучил. Она разбита на вкладки.</t>
<w>Важно:</w> в WoW 3.3.5 нет готовой функции <k>IsSpellKnown</k> и нет готовой функции <k>HasSpell</k>. Чтобы проверить, знает ли персонаж заклинание, нужно перебрать книгу заклинаний вручную.
<h>Вкладки книги</h>
<t>Книга заклинаний состоит из вкладок. Обычно это:</t>
<c>1</c> — основные заклинания класса.
<c>2</c> — таланты.
<c>3</c> — общие заклинания.
<c>4</c> — профессии и другие.
<h>GetNumSpellTabs</h>
<code>
/run print(GetNumSpellTabs())
</code>
<t>Возвращает количество вкладок книги заклинаний.</t>
<h>GetSpellTabInfo</h>
<code>
/run local name, texture, offset, numSpells = GetSpellTabInfo(1); print(name, offset, numSpells)
</code>
<t>Возвращает данные о вкладке:</t>
<c>name</c> — название вкладки.
<c>texture</c> — иконка вкладки.
<c>offset</c> — смещение индекса. Заклинания этой вкладки начинаются с offset + 1.
<c>numSpells</c> — количество заклинаний на вкладке.
<h>GetSpellBookItemName</h>
<code>
/run print(GetSpellBookItemName(1, "SPELL"))
</code>
<t>Возвращает имя заклинания по глобальному индексу в книге.</t>
<t>Второй аргумент — тип книги:</t>
<c>"SPELL"</c> — книга заклинаний.
<c>"PET"</c> — книга заклинаний питомца.
<h>GetSpellBookItemTexture</h>
<code>
/run print(GetSpellBookItemTexture(1, "SPELL"))
</code>
<t>Возвращает путь к иконке заклинания.</t>
<h>Перебор книги заклинаний</h>
<code>
/run local total = 0; local tabs = GetNumSpellTabs() or 0; for tab = 1, tabs do local _, _, offset, numSpells = GetSpellTabInfo(tab); if numSpells then total = total + numSpells end end; print("Всего заклинаний: " .. total)
</code>
<h>Поиск заклинания по имени</h>
<t>Чтобы проверить, знает ли персонаж заклинание, нужно перебрать книгу:</t>
<code>
/run local found = false; local tabs = GetNumSpellTabs() or 0; for tab = 1, tabs do local _, _, offset, numSpells = GetSpellTabInfo(tab); if numSpells then for i = 1, numSpells do local name = GetSpellBookItemName(offset + i, "SPELL"); if name and string.find(name, "Огн") then found = true end end end end; print(found)
</code>
<w>Важно:</w> имя заклинания зависит от языка клиента. Поэтому для надёжной проверки лучше использовать spellID, если он доступен.
<h>Поиск по spellID через GetSpellBookItemName</h>
<t>В WoW 3.3.5 нет прямой функции поиска по spellID в книге. Однако можно использовать <k>GetSpellInfo(spellID)</k> чтобы получить имя, а затем искать это имя в книге.</t>
<code>
/run local spellName = GetSpellInfo(6603); if spellName then print("Имя заклинания 6603: " .. spellName) end
</code>
<h>Безопасный шаблон</h>
<code>
/run local tabs = GetNumSpellTabs() or 0; print(string.format("Вкладок в книге: %d", tabs))
</code>
]=],
}

ns_llua['lua'][252] = {
type = "vartest",
title = "Тест 251-1: количество вкладок книги",
helpModules = {251, 65},
tasks = {
{
var = "spellTabCount",
desc = 'Создай глобальную переменную spellTabCount = GetNumSpellTabs() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "firstTabName",
desc = 'Создай глобальную переменную firstTabName = GetSpellTabInfo(1) or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
},
}

ns_llua['lua'][253] = {
type = "vartest",
title = "Тест 251-2: данные первой вкладки",
helpModules = {251, 65},
tasks = {
{
var = "firstTabOffset",
desc = 'Создай глобальную переменную firstTabOffset = select(3, GetSpellTabInfo(1)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "firstTabSpellCount",
desc = 'Создай глобальную переменную firstTabSpellCount = select(4, GetSpellTabInfo(1)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "firstSpellName",
desc = 'Создай глобальную переменную firstSpellName = GetSpellBookItemName(1, "SPELL") or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
},
}

ns_llua['lua'][254] = {
type = "commenttest",
title = "Тест 251-3: функция GetSpellTabCountSafe",
helpModules = {251, 45, 65},
preloadVars = {
{var = "GetSpellTabCountSafe", desc = "GetSpellTabCountSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 251-3: функция GetSpellTabCountSafe</h>
<t>Создай глобальную функцию <k>GetSpellTabCountSafe()</k>.</t>
<t>Функция должна вернуть количество вкладок книги заклинаний через:</t>
<code>
GetNumSpellTabs()
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть количество вкладок.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetSpellTabCountSafe()
]=],
requireKeywords = {
"GetSpellTabCountSafe",
"function",
"GetNumSpellTabs",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetSpellTabCountSafe) ~= "function" then
_G.checkError = "GetSpellTabCountSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetSpellTabCountSafe)
if not ok then
_G.checkError = "Ошибка вызова GetSpellTabCountSafe: " .. tostring(result)
return false
end
if type(result) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if result < 0 then
_G.checkError = "Количество вкладок не может быть отрицательным"
return false
end
return true
end,
}

ns_llua['lua'][255] = {
type = "commenttest",
title = "Тест 251-4: функция GetSpellBookItemNameSafe",
helpModules = {251, 45, 65},
preloadVars = {
{var = "GetSpellBookItemNameSafe", desc = "GetSpellBookItemNameSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 251-4: функция GetSpellBookItemNameSafe</h>
<t>Создай глобальную функцию <k>GetSpellBookItemNameSafe(index)</k>.</t>
<t>Если <k>index</k> не является числом или меньше либо равно нуля, функция должна вернуть строку:</t>
<s>"нет"</s>
<t>Иначе функция должна получить имя заклинания через:</t>
<code>
GetSpellBookItemName(index, "SPELL")
</code>
<t>Если результат не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"нет"</s>
<t>Иначе функция должна вернуть имя заклинания.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetSpellBookItemNameSafe(index)
]=],
requireKeywords = {
"GetSpellBookItemNameSafe",
"function",
"GetSpellBookItemName",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetSpellBookItemNameSafe) ~= "function" then
_G.checkError = "GetSpellBookItemNameSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetSpellBookItemNameSafe, 1)
if not ok1 then
_G.checkError = "Ошибка вызова GetSpellBookItemNameSafe(1): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для index = 1 функция должна вернуть строку"
return false
end
local ok2, result2 = pcall(_G.GetSpellBookItemNameSafe, 0)
if not ok2 or result2 ~= "нет" then
_G.checkError = "Для index = 0 функция должна вернуть 'нет'"
return false
end
local ok3, result3 = pcall(_G.GetSpellBookItemNameSafe, "bad")
if not ok3 or result3 ~= "нет" then
_G.checkError = "Для нечислового index функция должна вернуть 'нет'"
return false
end
return true
end,
}

ns_llua['lua'][256] = {
type = "commenttest",
title = "Тест 251-5: функция FindSpellInBook",
helpModules = {251, 45, 31, 33, 65},
preloadVars = {
{var = "FindSpellInBook", desc = "FindSpellInBook очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 251-5: функция FindSpellInBook</h>
<t>Создай глобальную функцию <k>FindSpellInBook(text)</k>.</t>
<t>Если <k>text</k> не является строкой или является пустой строкой, функция должна вернуть <k>false</k>.</t>
<t>Иначе функция должна перебрать все вкладки книги заклинаний и найти заклинание, в названии которого есть подстрока <k>text</k>.</t>
<t>Алгоритм:</t>
<t>1. Получи количество вкладок через <k>GetNumSpellTabs()</k>.</t>
<t>2. Для каждой вкладки получи <k>offset</k> и <k>numSpells</k> через <k>GetSpellTabInfo(tab)</k>.</t>
<t>3. Перебери заклинания от <k>offset + 1</k> до <k>offset + numSpells</k>.</t>
<t>4. Для каждого заклинания получи имя через <k>GetSpellBookItemName(index, "SPELL")</k>.</t>
<t>5. Если имя содержит подстроку <k>text</k>, верни <k>true</k>.</t>
<t>6. Если ничего не найдено, верни <k>false</k>.</t>
<t>Используй:</t>
<c>GetNumSpellTabs</c>
<c>GetSpellTabInfo</c>
<c>GetSpellBookItemName</c>
<c>string.find</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию FindSpellInBook(text)
]=],
requireKeywords = {
"FindSpellInBook",
"function",
"GetNumSpellTabs",
"GetSpellTabInfo",
"GetSpellBookItemName",
"string.find",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.FindSpellInBook) ~= "function" then
_G.checkError = "FindSpellInBook не является глобальной функцией"
return false
end
-- Тест 1: пустая строка
local ok1, result1 = pcall(_G.FindSpellInBook, "")
if not ok1 or result1 ~= false then
_G.checkError = "Для пустой строки функция должна вернуть false"
return false
end
-- Тест 2: не строка
local ok2, result2 = pcall(_G.FindSpellInBook, 123)
if not ok2 or result2 ~= false then
_G.checkError = "Для нестрокового аргумента функция должна вернуть false"
return false
end
-- Тест 3: несуществующая подстрока
local ok3, result3 = pcall(_G.FindSpellInBook, "zzz_no_such_spell_zzz")
if not ok3 then
_G.checkError = "Ошибка вызова FindSpellInBook с несуществующей строкой: " .. tostring(result3)
return false
end
if result3 ~= false then
_G.checkError = "Для несуществующей подстроки функция должна вернуть false"
return false
end
return true
end,
}

ns_llua['lua'][257] = {
type = "info",
title = "Backdrop: рамки и фоны фреймов",
helpModules = {215, 221, 227},
content = [=[
<h>Backdrop: рамки и фоны фреймов</h>
<t>В WoW 3.3.5 для создания красивых панелей с рамками и фонами используется метод <k>SetBackdrop</k>. Это основной способ стилизации фреймов.</t>
<w>Важно:</w> в современных версиях WoW этот метод убрали и заменили на NineSlice. Но в 3.3.5 именно <k>SetBackdrop</k> — единственный способ.
<h>Структура backdropInfo</h>
<t>Backdrop задаётся таблицей со следующими полями:</t>
<code>
local backdropInfo = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
</code>
<t>Поля:</t>
<c>bgFile</c> — путь к текстуре фона.
<c>edgeFile</c> — путь к текстуре рамки.
<c>tile</c> — тайлить фон (повторять текстуру).
<c>tileSize</c> — размер тайла фона.
<c>edgeSize</c> — толщина рамки.
<c>insets</c> — отступ фона от краёв рамки.
<h>Применение SetBackdrop</h>
<code>
MyStyledFrame = CreateFrame("Frame", "MyStyledFrame", UIParent)
MyStyledFrame:SetSize(250, 180)
MyStyledFrame:SetPoint("CENTER")
MyStyledFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
MyStyledFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
MyStyledFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
MyStyledFrame:Show()
</code>
<h>SetBackdropColor</h>
<t>Устанавливает цвет фона. Четыре аргумента: R, G, B, A (от 0 до 1).</t>
<code>
MyStyledFrame:SetBackdropColor(0, 0, 0, 0.8)   -- чёрный полупрозрачный
MyStyledFrame:SetBackdropColor(0.2, 0.1, 0.1, 1) -- тёмно-красный
</code>
<h>SetBackdropBorderColor</h>
<t>Устанавливает цвет рамки. Формат тот же: R, G, B, A.</t>
<code>
MyStyledFrame:SetBackdropBorderColor(1, 0.84, 0, 1) -- золотая рамка
</code>
<h>Популярные текстуры Blizzard</h>
<c>"Interface\\Tooltips\\UI-Tooltip-Background"</c> — гладкий фон.
<c>"Interface\\Tooltips\\UI-Tooltip-Border"</c> — тонкая рамка.
<c>"Interface\\DialogFrame\\UI-DialogBox-Background"</c> — фон диалога.
<c>"Interface\\DialogFrame\\UI-DialogBox-Border"</c> — рамка диалога.
<c>"Interface\\ChatFrame\\ChatFrameBackground"</c> — фон чата.
<c>"Interface\\Buttons\\WHITE8x8"</c> — белый квадрат (универсальный).
<h>Шаблоны с backdrop</h>
<t>Некоторые шаблоны уже содержат backdrop:</t>
<code>
MyDialog = CreateFrame("Frame", "MyDialog", UIParent, "UIPanelDialogTemplate")
</code>
<t>Но для полного контроля лучше задавать backdrop вручную.</t>
<h>Частые ошибки</h>
<w>Ошибка 1:</w> забыть двойной обратный слеш в путях.
<code>
-- неправильно
bgFile = "Interface\Tooltips\UI-Tooltip-Background"
-- правильно
bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
</code>
<w>Ошибка 2:</w> вызвать SetBackdropColor до SetBackdrop. Сначала нужно задать backdrop, потом менять цвет.
<w>Ошибка 3:</w> не указать insets. Без них фон может залезать под рамку.
]=],
}

ns_llua['lua'][258] = {
type = "vartest",
title = "Тест 258: пути текстур backdrop",
helpModules = {257},
tasks = {
{
var = "backdropBgPath",
desc = 'Создай глобальную переменную backdropBgPath = "Interface\\\\Tooltips\\\\UI-Tooltip-Background"',
check = function(value)
return type(value) == "string" and value:find("UI%-Tooltip%-Background") ~= nil
end,
},
{
var = "backdropEdgePath",
desc = 'Создай глобальную переменную backdropEdgePath = "Interface\\\\Tooltips\\\\UI-Tooltip-Border"',
check = function(value)
return type(value) == "string" and value:find("UI%-Tooltip%-Border") ~= nil
end,
},
{
var = "backdropTileSize",
desc = 'Создай глобальную переменную backdropTileSize = 16',
check = function(value)
return type(value) == "number" and value == 16
end,
},
},
}

ns_llua['lua'][259] = {
type = "commenttest",
title = "Тест 259: фрейм с backdrop",
helpModules = {257, 215, 221},
preloadVars = {
{var = "CourseBackdropFrame", desc = "CourseBackdropFrame очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 233-2: фрейм с backdrop</h>
<t>Создай глобальный фрейм <k>CourseBackdropFrame</k>.</t>
<t>Требования:</t>
<t>- тип: <s>"Frame"</s>, глобальное имя: <s>"CourseBackdropFrame"</s>, родитель: <k>UIParent</k>;</t>
<t>- размер: 260 на 160;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- примени <k>SetBackdrop</k> с таблицей:</t>
<c>bgFile</c> = "Interface\\Tooltips\\UI-Tooltip-Background"
<c>edgeFile</c> = "Interface\\Tooltips\\UI-Tooltip-Border"
<c>tile</c> = true
<c>tileSize</c> = 16
<c>edgeSize</c> = 16
<c>insets</c> = { left = 4, right = 4, top = 4, bottom = 4 }
<t>- установи цвет фона: <k>SetBackdropColor(0.05, 0.05, 0.05, 0.9)</k>;</t>
<t>- установи цвет рамки: <k>SetBackdropBorderColor(0.6, 0.6, 0.6, 1)</k>;</t>
<t>- покажи фрейм.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CourseBackdropFrame с backdrop
]=],
requireKeywords = {
"CourseBackdropFrame",
"CreateFrame",
"SetBackdrop",
"bgFile",
"edgeFile",
"SetBackdropColor",
"SetBackdropBorderColor",
"Show",
},
checkCode = function()
_G.checkError = nil
local f = _G.CourseBackdropFrame
if not f or type(f.IsShown) ~= "function" then
_G.checkError = "CourseBackdropFrame не является фреймом"
return false
end
if not f:IsShown() then
_G.checkError = "Фрейм должен быть показан"
return false
end
if f:GetWidth() ~= 260 or f:GetHeight() ~= 160 then
_G.checkError = "Размер фрейма должен быть 260 на 160"
return false
end
if type(f.GetBackdrop) ~= "function" then
_G.checkError = "У фрейма должен быть метод GetBackdrop"
return false
end
local bd = f:GetBackdrop()
if type(bd) ~= "table" then
_G.checkError = "Backdrop не был применён"
return false
end
if type(bd.bgFile) ~= "string" or bd.bgFile == "" then
_G.checkError = "bgFile должен быть непустой строкой"
return false
end
if type(bd.edgeFile) ~= "string" or bd.edgeFile == "" then
_G.checkError = "edgeFile должен быть непустой строкой"
return false
end
return true
end,
}

ns_llua['lua'][260] = {
type = "commenttest",
title = "Тест 260: функция ApplyBackdrop",
helpModules = {257, 215, 45, 65},
preloadVars = {
{var = "ApplyBackdrop", desc = "ApplyBackdrop очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 233-3: функция ApplyBackdrop</h>
<t>Создай глобальную функцию <k>ApplyBackdrop(frame, r, g, b, a)</k>.</t>
<t>Требования:</t>
<t>- если <k>frame</k> не существует или у него нет метода <k>SetBackdrop</k>, верни <k>false</k>;</t>
<t>- если <k>r</k>, <k>g</k>, <k>b</k> не являются числами, верни <k>false</k>;</t>
<t>- если <k>a</k> не является числом, используй <n>1</n>;</t>
<t>- иначе примени стандартный backdrop с bgFile <s>"Interface\\Tooltips\\UI-Tooltip-Background"</s> и edgeFile <s>"Interface\\Tooltips\\UI-Tooltip-Border"</s>;</t>
<t>- установи цвет фона через <k>SetBackdropColor(r, g, b, a)</k>;</t>
<t>- установи цвет рамки через <k>SetBackdropBorderColor(0.5, 0.5, 0.5, 1)</k>;</t>
<t>- верни <k>true</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию ApplyBackdrop(frame, r, g, b, a)
]=],
requireKeywords = {
"ApplyBackdrop",
"function",
"SetBackdrop",
"SetBackdropColor",
"SetBackdropBorderColor",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.ApplyBackdrop) ~= "function" then
_G.checkError = "ApplyBackdrop не является глобальной функцией"
return false
end
local testFrame = CreateFrame("Frame", nil, UIParent)
testFrame:SetSize(100, 100)
local ok1, result1 = pcall(_G.ApplyBackdrop, testFrame, 0.1, 0.1, 0.1, 0.8)
if not ok1 then
_G.checkError = "Ошибка вызова ApplyBackdrop: " .. tostring(result1)
return false
end
if result1 ~= true then
_G.checkError = "Для корректного фрейма функция должна вернуть true"
return false
end
local bd = testFrame:GetBackdrop()
if type(bd) ~= "table" or type(bd.bgFile) ~= "string" then
_G.checkError = "Backdrop не был применён"
return false
end
local ok2, result2 = pcall(_G.ApplyBackdrop, nil, 0, 0, 0, 1)
if not ok2 or result2 ~= false then
_G.checkError = "Для nil-фрейма функция должна вернуть false"
return false
end
local ok3, result3 = pcall(_G.ApplyBackdrop, testFrame, "bad", 0, 0, 1)
if not ok3 or result3 ~= false then
_G.checkError = "Для нечислового r функция должна вернуть false"
return false
end
return true
end,
}

ns_llua['lua'][261] = {
type = "commenttest",
title = "Тест 261: функция SetFrameBackdropColor",
helpModules = {257, 45, 65, 21},
preloadVars = {
{var = "SetFrameBackdropColor", desc = "SetFrameBackdropColor очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 233-4: функция SetFrameBackdropColor</h>
<t>Создай глобальную функцию <k>SetFrameBackdropColor(frame, r, g, b, a)</k>.</t>
<t>Требования:</t>
<t>- если <k>frame</k> не существует или у него нет метода <k>SetBackdropColor</k>, верни <k>false</k>;</t>
<t>- если любой из аргументов <k>r</k>, <k>g</k>, <k>b</k> не является числом, верни <k>false</k>;</t>
<t>- если <k>a</k> не является числом, используй <n>1</n>;</t>
<t>- ограничь каждое значение от 0 до 1 через <k>math.max(0, math.min(1, value))</k>;</t>
<t>- вызови <k>frame:SetBackdropColor(r, g, b, a)</k>;</t>
<t>- верни <k>true</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию SetFrameBackdropColor(frame, r, g, b, a)
]=],
requireKeywords = {
"SetFrameBackdropColor",
"function",
"SetBackdropColor",
"math.max",
"math.min",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.SetFrameBackdropColor) ~= "function" then
_G.checkError = "SetFrameBackdropColor не является глобальной функцией"
return false
end
local testFrame = CreateFrame("Frame", nil, UIParent)
testFrame:SetSize(80, 80)
testFrame:SetBackdrop({
bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
tile = true, tileSize = 16, edgeSize = 16,
insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
local ok1, result1 = pcall(_G.SetFrameBackdropColor, testFrame, 0.5, 0.3, 0.1, 0.9)
if not ok1 then
_G.checkError = "Ошибка вызова SetFrameBackdropColor: " .. tostring(result1)
return false
end
if result1 ~= true then
_G.checkError = "Для корректных данных функция должна вернуть true"
return false
end
local ok2, result2 = pcall(_G.SetFrameBackdropColor, nil, 0, 0, 0, 1)
if not ok2 or result2 ~= false then
_G.checkError = "Для nil-фрейма функция должна вернуть false"
return false
end
local ok3, result3 = pcall(_G.SetFrameBackdropColor, testFrame, 2, 0, 0, 1)
if not ok3 then
_G.checkError = "Ошибка при r > 1: " .. tostring(result3)
return false
end
if result3 ~= true then
_G.checkError = "Для r > 1 функция должна вернуть true (с клампом)"
return false
end
return true
end,
}

ns_llua['lua'][262] = {
type = "commenttest",
title = "Тест 262: функция CreateStyledPanel",
helpModules = {257, 215, 221, 227, 45, 65},
preloadVars = {
{var = "CreateStyledPanel", desc = "CreateStyledPanel очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 233-5: функция CreateStyledPanel</h>
<t>Создай глобальную функцию <k>CreateStyledPanel(name, width, height, title)</k>.</t>
<t>Требования:</t>
<t>- если <k>name</k> не строка или пустая, верни <k>nil</k>;</t>
<t>- если <k>width</k> или <k>height</k> не числа или меньше 50, верни <k>nil</k>;</t>
<t>- если <k>title</k> не строка, используй пустую строку;</t>
<t>- создай фрейм типа <s>"Frame"</s> с именем <k>name</k>, родитель <k>UIParent</k>;</t>
<t>- размер: <k>width</k> на <k>height</k>;</t>
<t>- позиция: CENTER;</t>
<t>- примени backdrop с bgFile и edgeFile из Tooltips;</t>
<t>- цвет фона: чёрный полупрозрачный (0, 0, 0, 0.85);</t>
<t>- цвет рамки: серый (0.5, 0.5, 0.5, 1);</t>
<t>- создай FontString заголовок слоем OVERLAY, шаблон GameFontNormalLarge;</t>
<t>- позиция заголовка: TOP, смещение 0, -10;</t>
<t>- текст заголовка: <k>title</k>;</t>
<t>- покажи фрейм;</t>
<t>- верни фрейм.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CreateStyledPanel(name, width, height, title)
]=],
requireKeywords = {
"CreateStyledPanel",
"function",
"CreateFrame",
"SetBackdrop",
"SetBackdropColor",
"CreateFontString",
"SetText",
"Show",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CreateStyledPanel) ~= "function" then
_G.checkError = "CreateStyledPanel не является глобальной функцией"
return false
end
local ok1, f1 = pcall(_G.CreateStyledPanel, "NS_Test_Panel_1", 200, 150, "Заголовок")
if not ok1 then
_G.checkError = "Ошибка вызова CreateStyledPanel: " .. tostring(f1)
return false
end
if not f1 or type(f1.IsShown) ~= "function" then
_G.checkError = "Функция должна вернуть фрейм"
return false
end
if not f1:IsShown() then
_G.checkError = "Фрейм должен быть показан"
return false
end
if f1:GetWidth() ~= 200 or f1:GetHeight() ~= 150 then
_G.checkError = "Размер фрейма должен быть 200 на 150"
return false
end
local bd = f1:GetBackdrop()
if type(bd) ~= "table" or type(bd.bgFile) ~= "string" then
_G.checkError = "Backdrop должен быть применён"
return false
end
local ok2, f2 = pcall(_G.CreateStyledPanel, "", 200, 150, "Тест")
if not ok2 or f2 ~= nil then
_G.checkError = "Для пустого имени функция должна вернуть nil"
return false
end
local ok3, f3 = pcall(_G.CreateStyledPanel, "NS_Test_Panel_2", 30, 150, "Тест")
if not ok3 or f3 ~= nil then
_G.checkError = "Для width < 50 функция должна вернуть nil"
return false
end
return true
end,
}

ns_llua['lua'][263] = {
type = "info",
title = "Тултипы: GameTooltip и подсказки",
helpModules = {215, 227, 233},
content = [=[
<h>Тултипы: GameTooltip и подсказки</h>
<t>Тултип — это всплывающая подсказка, которая появляется при наведении курсора на элемент интерфейса. В WoW 3.3.5 есть глобальный объект <k>GameTooltip</k>, который можно использовать для показа информации.</t>
<h>Основные методы GameTooltip</h>
<c>GameTooltip:SetOwner(frame, anchor)</c> — привязать тултип к фрейму.
<c>GameTooltip:SetText(text)</c> — установить основной текст.
<c>GameTooltip:AddLine(text, r, g, b)</c> — добавить строку.
<c>GameTooltip:AddDoubleLine(left, right)</c> — добавить строку с двумя колонками.
<c>GameTooltip:Show()</c> — показать тултип.
<c>GameTooltip:Hide()</c> — скрыть тултип.
<h>SetOwner</h>
<t>Перед показом тултипа нужно указать, к какому фрейму он привязан:</t>
<code>
GameTooltip:SetOwner(MyFrame, "ANCHOR_TOPRIGHT")
</code>
<t>Варианты привязки:</t>
<c>"ANCHOR_TOP"</c> — над фреймом.
<c>"ANCHOR_BOTTOM"</c> — под фреймом.
<c>"ANCHOR_LEFT"</c> — слева.
<c>"ANCHOR_RIGHT"</c> — справа.
<c>"ANCHOR_TOPRIGHT"</c> — в правом верхнем углу.
<c>"ANCHOR_CURSOR"</c> — у курсора мыши.
<h>OnEnter и OnLeave</h>
<t>Тултипы показываются при наведении мыши. Для этого используются скрипты <k>OnEnter</k> и <k>OnLeave</k>:</t>
<code>
MyFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
    GameTooltip:SetText("Мой фрейм")
    GameTooltip:AddLine("Описание фрейма", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
MyFrame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
</code>
<h>Показ предмета через SetHyperlink</h>
<t>Чтобы показать стандартный тултип предмета:</t>
<code>
GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
GameTooltip:SetHyperlink("item:6948:0:0:0:0:0:0:0")
GameTooltip:Show()
</code>
<t>Или через ссылку:</t>
<code>
local _, link = GetItemInfo(6948)
if link then
    GameTooltip:SetHyperlink(link)
end
</code>
<h>Показ заклинания</h>
<code>
GameTooltip:SetSpellByID(6603)
</code>
<h>AddLine с цветом</h>
<code>
GameTooltip:AddLine("Красный текст", 1, 0, 0)
GameTooltip:AddLine("Зелёный текст", 0, 1, 0)
GameTooltip:AddLine("Белый текст", 1, 1, 1)
</code>
<h>AddDoubleLine</h>
<code>
GameTooltip:AddDoubleLine("Слева", "Справа", 1, 1, 1, 0.8, 0.8, 0.8)
</code>
<h>GameTooltip_SetDefaultAnchor</h>
<t>Стандартная функция для привязки тултипа к курсору:</t>
<code>
GameTooltip_SetDefaultAnchor(GameTooltip, self)
</code>
<t>Это эквивалент <k>GameTooltip:SetOwner(self, "ANCHOR_CURSOR")</k>.</t>
<h>Важные правила</h>
<w>Правило 1:</w> всегда вызывай <k>GameTooltip:Hide()</k> в OnLeave. Иначе тултип останется на экране.
<w>Правило 2:</w> перед AddLine вызови SetText или SetOwner. Иначе тултип может быть пустым.
<w>Правило 3:</w> не показывай тултип в бою, если он может блокировать обзор.
]=],
}

ns_llua['lua'][264] = {
type = "vartest",
title = "Тест 264: константы тултипов",
helpModules = {263},
tasks = {
{
var = "tooltipAnchorTop",
desc = 'Создай глобальную переменную tooltipAnchorTop = "ANCHOR_TOP"',
check = function(value)
return value == "ANCHOR_TOP"
end,
},
{
var = "tooltipAnchorCursor",
desc = 'Создай глобальную переменную tooltipAnchorCursor = "ANCHOR_CURSOR"',
check = function(value)
return value == "ANCHOR_CURSOR"
end,
},
{
var = "tooltipExists",
desc = 'Создай глобальную переменную tooltipExists = (type(GameTooltip) ~= "nil")',
check = function(value)
return value == true
end,
},
},
}

ns_llua['lua'][265] = {
type = "commenttest",
title = "Тест 265: фрейм с тултипом",
helpModules = {263, 215, 221},
preloadVars = {
{var = "CourseTooltipFrame", desc = "CourseTooltipFrame очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 239-2: фрейм с тултипом</h>
<t>Создай глобальный фрейм <k>CourseTooltipFrame</k>.</t>
<t>Требования:</t>
<t>- тип: <s>"Frame"</s>, глобальное имя: <s>"CourseTooltipFrame"</s>, родитель: <k>UIParent</k>;</t>
<t>- размер: 150 на 100;</t>
<t>- позиция: CENTER;</t>
<t>- включи мышку через <k>EnableMouse(true)</k>;</t>
<t>- назначь скрипт <k>OnEnter</k>, который:</t>
<c>вызывает GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")</c>
<c>вызывает GameTooltip:SetText("Тестовый фрейм")</c>
<c>вызывает GameTooltip:AddLine("Наведи и прочитай", 0.8, 0.8, 0.8)</c>
<c>вызывает GameTooltip:Show()</c>
<t>- назначь скрипт <k>OnLeave</k>, который вызывает <k>GameTooltip:Hide()</k>;</t>
<t>- покажи фрейм.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм CourseTooltipFrame с тултипом
]=],
requireKeywords = {
"CourseTooltipFrame",
"CreateFrame",
"EnableMouse",
"SetScript",
"OnEnter",
"OnLeave",
"GameTooltip",
"SetOwner",
"SetText",
"AddLine",
"Show",
"Hide",
},
checkCode = function()
_G.checkError = nil
local f = _G.CourseTooltipFrame
if not f or type(f.GetScript) ~= "function" then
_G.checkError = "CourseTooltipFrame не является фреймом"
return false
end
if not f:IsShown() then
_G.checkError = "Фрейм должен быть показан"
return false
end
if f:GetWidth() ~= 150 or f:GetHeight() ~= 100 then
_G.checkError = "Размер фрейма должен быть 150 на 100"
return false
end
local onEnter = f:GetScript("OnEnter")
if type(onEnter) ~= "function" then
_G.checkError = "У фрейма должен быть обработчик OnEnter"
return false
end
local onLeave = f:GetScript("OnLeave")
if type(onLeave) ~= "function" then
_G.checkError = "У фрейма должен быть обработчик OnLeave"
return false
end
return true
end,
}

ns_llua['lua'][266] = {
type = "commenttest",
title = "Тест 266: функция ShowItemTooltip",
helpModules = {263, 179, 45, 65},
preloadVars = {
{var = "ShowItemTooltip", desc = "ShowItemTooltip очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 239-3: функция ShowItemTooltip</h>
<t>Создай глобальную функцию <k>ShowItemTooltip(frame, itemID)</k>.</t>
<t>Требования:</t>
<t>- если <k>frame</k> не существует или у него нет метода <k>GetScript</k>, верни <k>false</k>;</t>
<t>- если <k>itemID</k> не является числом или меньше либо равно нуля, верни <k>false</k>;</t>
<t>- иначе назначь скрипт <k>OnEnter</k> на фрейм, который:</t>
<c>вызывает GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")</c>
<c>вызывает GameTooltip:SetHyperlink("item:" .. itemID)</c>
<c>вызывает GameTooltip:Show()</c>
<t>- назначь скрипт <k>OnLeave</k>, который вызывает <k>GameTooltip:Hide()</k>;</t>
<t>- верни <k>true</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию ShowItemTooltip(frame, itemID)
]=],
requireKeywords = {
"ShowItemTooltip",
"function",
"GameTooltip",
"SetOwner",
"SetHyperlink",
"OnEnter",
"OnLeave",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.ShowItemTooltip) ~= "function" then
_G.checkError = "ShowItemTooltip не является глобальной функцией"
return false
end
local testFrame = CreateFrame("Frame", nil, UIParent)
testFrame:SetSize(64, 64)
local ok1, result1 = pcall(_G.ShowItemTooltip, testFrame, 6948)
if not ok1 then
_G.checkError = "Ошибка вызова ShowItemTooltip: " .. tostring(result1)
return false
end
if result1 ~= true then
_G.checkError = "Для корректных данных функция должна вернуть true"
return false
end
local onEnter = testFrame:GetScript("OnEnter")
if type(onEnter) ~= "function" then
_G.checkError = "OnEnter должен быть назначен"
return false
end
local onLeave = testFrame:GetScript("OnLeave")
if type(onLeave) ~= "function" then
_G.checkError = "OnLeave должен быть назначен"
return false
end
local ok2, result2 = pcall(_G.ShowItemTooltip, nil, 6948)
if not ok2 or result2 ~= false then
_G.checkError = "Для nil-фрейма функция должна вернуть false"
return false
end
local ok3, result3 = pcall(_G.ShowItemTooltip, testFrame, -1)
if not ok3 or result3 ~= false then
_G.checkError = "Для отрицательного itemID функция должна вернуть false"
return false
end
return true
end,
}

ns_llua['lua'][267] = {
type = "commenttest",
title = "Тест 267: функция ShowCustomTooltip",
helpModules = {263, 45, 65},
preloadVars = {
{var = "ShowCustomTooltip", desc = "ShowCustomTooltip очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 239-4: функция ShowCustomTooltip</h>
<t>Создай глобальную функцию <k>ShowCustomTooltip(frame, title, lines)</k>.</t>
<t>Аргументы:</t>
<c>frame</c> — фрейм-владелец.
<c>title</c> — строка-заголовок.
<c>lines</c> — таблица-массив со строками для дополнительных линий.
<t>Требования:</t>
<t>- если <k>frame</k> не существует, верни <k>false</k>;</t>
<t>- если <k>title</k> не строка, используй пустую строку;</t>
<t>- если <k>lines</k> не таблица, используй пустую таблицу;</t>
<t>- назначь OnEnter на фрейм, который:</t>
<c>GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT")</c>
<c>GameTooltip:SetText(title, 1, 0.84, 0)</c>
<c>для каждой строки из lines: GameTooltip:AddLine(line, 0.8, 0.8, 0.8)</c>
<c>GameTooltip:Show()</c>
<t>- назначь OnLeave с GameTooltip:Hide();</t>
<t>- верни <k>true</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию ShowCustomTooltip(frame, title, lines)
]=],
requireKeywords = {
"ShowCustomTooltip",
"function",
"GameTooltip",
"SetOwner",
"SetText",
"AddLine",
"OnEnter",
"OnLeave",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.ShowCustomTooltip) ~= "function" then
_G.checkError = "ShowCustomTooltip не является глобальной функцией"
return false
end
local testFrame = CreateFrame("Frame", nil, UIParent)
testFrame:SetSize(100, 100)
local ok1, result1 = pcall(_G.ShowCustomTooltip, testFrame, "Заголовок", {"Строка 1", "Строка 2"})
if not ok1 then
_G.checkError = "Ошибка вызова ShowCustomTooltip: " .. tostring(result1)
return false
end
if result1 ~= true then
_G.checkError = "Для корректных данных функция должна вернуть true"
return false
end
local onEnter = testFrame:GetScript("OnEnter")
if type(onEnter) ~= "function" then
_G.checkError = "OnEnter должен быть назначен"
return false
end
local ok2, result2 = pcall(_G.ShowCustomTooltip, nil, "Тест", {})
if not ok2 or result2 ~= false then
_G.checkError = "Для nil-фрейма функция должна вернуть false"
return false
end
local ok3, result3 = pcall(_G.ShowCustomTooltip, testFrame, nil, nil)
if not ok3 or result3 ~= true then
_G.checkError = "Для nil-title и nil-lines функция должна вернуть true (с дефолтами)"
return false
end
return true
end,
}

ns_llua['lua'][268] = {
type = "commenttest",
title = "Тест 268: функция CreateTooltipButton",
helpModules = {263, 233, 215, 45, 65},
preloadVars = {
{var = "CreateTooltipButton", desc = "CreateTooltipButton очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 239-5: функция CreateTooltipButton</h>
<t>Создай глобальную функцию <k>CreateTooltipButton(name, text, tooltipText)</k>.</t>
<t>Требования:</t>
<t>- если <k>name</k> не строка или пустая, верни <k>nil</k>;</t>
<t>- если <k>text</k> не строка, используй <s>"Кнопка"</s>;</t>
<t>- если <k>tooltipText</k> не строка, используй пустую строку;</t>
<t>- создай кнопку типа <s>"Button"</s> с именем <k>name</k>, родитель <k>UIParent</k>;</t>
<t>- размер: 140 на 35;</t>
<t>- позиция: CENTER;</t>
<t>- создай FontString для кнопки с текстом <k>text</k>;</t>
<t>- назначь OnEnter: GameTooltip:SetOwner, SetText(tooltipText), Show;</t>
<t>- назначь OnLeave: GameTooltip:Hide();</t>
<t>- покажи кнопку;</t>
<t>- верни кнопку.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CreateTooltipButton(name, text, tooltipText)
]=],
requireKeywords = {
"CreateTooltipButton",
"function",
"CreateFrame",
"Button",
"CreateFontString",
"SetText",
"OnEnter",
"OnLeave",
"GameTooltip",
"Show",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CreateTooltipButton) ~= "function" then
_G.checkError = "CreateTooltipButton не является глобальной функцией"
return false
end
local ok1, btn = pcall(_G.CreateTooltipButton, "NS_TT_Btn_1", "Нажми", "Подсказка")
if not ok1 then
_G.checkError = "Ошибка вызова CreateTooltipButton: " .. tostring(btn)
return false
end
if not btn or type(btn.GetScript) ~= "function" then
_G.checkError = "Функция должна вернуть кнопку"
return false
end
if not btn:IsShown() then
_G.checkError = "Кнопка должна быть показана"
return false
end
local onEnter = btn:GetScript("OnEnter")
if type(onEnter) ~= "function" then
_G.checkError = "У кнопки должен быть OnEnter"
return false
end
local onLeave = btn:GetScript("OnLeave")
if type(onLeave) ~= "function" then
_G.checkError = "У кнопки должен быть OnLeave"
return false
end
local ok2, result2 = pcall(_G.CreateTooltipButton, "", "Текст", "Тултип")
if not ok2 or result2 ~= nil then
_G.checkError = "Для пустого имени функция должна вернуть nil"
return false
end
return true
end,
}

ns_llua['lua'][269] = {
type = "info",
title = "Слэш-команды: SlashCmdList",
helpModules = {239, 215},
content = [=[
<h>Слэш-команды: SlashCmdList</h>
<t>Слэш-команды позволяют игроку управлять аддоном через чат. Например, <k>/panel show</k> или <k>/panel reset</k>.</t>
<h>Как это работает</h>
<t>WoW использует две вещи для регистрации команды:</t>
<c>1</c> — глобальная переменная <k>SLASH_ИМЯ1</k> содержит текст команды.
<c>2</c> — таблица <k>SlashCmdList["ИМЯ"]</k> содержит функцию-обработчик.
<h>Простой пример</h>
<code>
SLASH_MYADDON1 = "/myaddon"
SlashCmdList["MYADDON"] = function(msg)
    print("Вы ввели: " .. msg)
end
</code>
<t>После этого в чате можно написать:</t>
<code>
/myaddon hello
</code>
<t>И в чат выведется: <s>"Вы ввели: hello"</s></t>
<h>Несколько алиасов</h>
<t>Можно зарегистрировать несколько вариантов команды:</t>
<code>
SLASH_MYADDON1 = "/myaddon"
SLASH_MYADDON2 = "/ma"
SlashCmdList["MYADDON"] = function(msg)
    print("Команда вызвана с: " .. msg)
end
</code>
<t>Теперь работают и <k>/myaddon</k>, и <k>/ma</k>.</t>
<h>Аргумент msg</h>
<t>Аргумент <k>msg</k> — это всё, что игрок написал после команды. Если написать <k>/myaddon show all</k>, то <k>msg</k> будет равен <s>"show all"</s>.</t>
<h>Разбиение аргументов</h>
<code>
SLASH_MYADDON1 = "/myaddon"
SlashCmdList["MYADDON"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end
    local cmd = args[1] or ""
    if cmd == "show" then
        print("Показываю")
    elseif cmd == "hide" then
        print("Скрываю")
    elseif cmd == "reset" then
        print("Сбрасываю")
    else
        print("Неизвестная команда: " .. cmd)
    end
end
</code>
<h>Типичные подкоманды</h>
<c>show</c> — показать фрейм.
<c>hide</c> — скрыть фрейм.
<c>toggle</c> — переключить видимость.
<c>reset</c> — сбросить позицию или настройки.
<c>config</c> — открыть настройки.
<c>help</c> — показать список команд.
<h>Безопасный шаблон</h>
<code>
SLASH_NSPANEL1 = "/nspanel"
SLASH_NSPANEL2 = "/nsp"
SlashCmdList["NSPANEL"] = function(msg)
    msg = msg or ""
    msg = msg:lower()
    msg = msg:gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" or msg == "help" then
        print("/nspanel show|hide|toggle|reset")
    elseif msg == "show" then
        -- показать
    elseif msg == "hide" then
        -- скрыть
    elseif msg == "toggle" then
        -- переключить
    elseif msg == "reset" then
        -- сбросить
    else
        print("Неизвестная подкоманда: " .. msg)
    end
end
</code>
<h>Частые ошибки</h>
<w>Ошибка 1:</w> имя в SlashCmdList должно совпадать с суффиксом SLASH_ИМЯ. Если переменная <k>SLASH_MYADDON1</k>, то ключ в SlashCmdList — <s>"MYADDON"</s>.
<w>Ошибка 2:</w> забыть привести msg к нижнему регистру. Игрок может написать <k>/panel SHOW</k>.
<w>Ошибка 3:</w> не обрабатывать пустой msg. Игрок может написать просто <k>/panel</k> без аргументов.
]=],
}

ns_llua['lua'][270] = {
type = "vartest",
title = "Тест 270: структура слэш-команд",
helpModules = {269},
tasks = {
{
var = "slashCmdPrefix",
desc = 'Создай глобальную переменную slashCmdPrefix = "SLASH_"',
check = function(value)
return value == "SLASH_"
end,
},
{
var = "slashCmdListType",
desc = 'Создай глобальную переменную slashCmdListType = type(SlashCmdList)',
check = function(value)
return value == "table"
end,
},
{
var = "slashCmdTest",
desc = 'Создай глобальную переменную slashCmdTest = "/testcmd"',
check = function(value)
return value == "/testcmd"
end,
},
},
}

ns_llua['lua'][271] = {
type = "commenttest",
title = "Тест 271: регистрация слэш-команды",
helpModules = {269, 45},
preloadVars = {
{var = "nsSlashTestLog", desc = "nsSlashTestLog очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError", "nsSlashTestLog"},
instruction = [=[
<h>Тест 245-2: регистрация слэш-команды</h>
<t>Зарегистрируй слэш-команду:</t>
<t>- создай глобальную переменную <k>nsSlashTestLog</k> со значением <s>""</s>;</t>
<t>- создай глобальную переменную <k>SLASH_NSTEST1</k> со значением <s>"/nstest"</s>;</t>
<t>- создай обработчик в <k>SlashCmdList["NSTEST"]</k>;</t>
<t>- обработчик должен записывать аргумент <k>msg</k> в <k>nsSlashTestLog</k>;</t>
<t>- если <k>msg</k> равен <k>nil</k>, запиши пустую строку.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Зарегистрируй слэш-команду /nstest
]=],
requireKeywords = {
"SLASH_NSTEST1",
"SlashCmdList",
"NSTEST",
"function",
"nsSlashTestLog",
},
checkCode = function()
_G.checkError = nil
if _G.SLASH_NSTEST1 ~= "/nstest" then
_G.checkError = "SLASH_NSTEST1 должна быть '/nstest'"
return false
end
local handler = SlashCmdList["NSTEST"]
if type(handler) ~= "function" then
_G.checkError = "SlashCmdList['NSTEST'] должна быть функцией"
return false
end
_G.nsSlashTestLog = nil
local ok, err = pcall(handler, "hello world")
if not ok then
_G.checkError = "Ошибка вызова обработчика: " .. tostring(err)
return false
end
if _G.nsSlashTestLog ~= "hello world" then
_G.checkError = "Обработчик должен записать msg в nsSlashTestLog"
return false
end
_G.nsSlashTestLog = nil
local ok2, err2 = pcall(handler, nil)
if not ok2 then
_G.checkError = "Ошибка вызова обработчика с nil: " .. tostring(err2)
return false
end
if _G.nsSlashTestLog ~= "" then
_G.checkError = "Для nil msg обработчик должен записать пустую строку"
return false
end
return true
end,
}

ns_llua['lua'][272] = {
type = "commenttest",
title = "Тест 272: функция ParseSlashArgs",
helpModules = {269, 45, 31, 44},
preloadVars = {
{var = "ParseSlashArgs", desc = "ParseSlashArgs очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 245-3: функция ParseSlashArgs</h>
<t>Создай глобальную функцию <k>ParseSlashArgs(msg)</k>.</t>
<t>Требования:</t>
<t>- если <k>msg</k> не строка, верни пустую таблицу <k>{}</k>;</t>
<t>- иначе разбей строку по пробелам и верни таблицу-массив со словами;</t>
<t>- пустые строки и лишние пробелы должны игнорироваться;</t>
<t>- все слова должны быть в нижнем регистре через <k>string.lower</k>;</t>
<t>- используй <k>string.gmatch</k> с паттерном <s>"%S+"</s>;</t>
<t>- используй <k>table.insert</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию ParseSlashArgs(msg)
]=],
requireKeywords = {
"ParseSlashArgs",
"function",
"string.gmatch",
"string.lower",
"table.insert",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.ParseSlashArgs) ~= "function" then
_G.checkError = "ParseSlashArgs не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.ParseSlashArgs, "show all")
if not ok1 then
_G.checkError = "Ошибка вызова ParseSlashArgs: " .. tostring(result1)
return false
end
if type(result1) ~= "table" or #result1 ~= 2 then
_G.checkError = "Для 'show all' функция должна вернуть таблицу из 2 элементов"
return false
end
if result1[1] ~= "show" or result1[2] ~= "all" then
_G.checkError = "Элементы таблицы неверны"
return false
end
local ok2, result2 = pcall(_G.ParseSlashArgs, "  SHOW   ALL  ")
if not ok2 or type(result2) ~= "table" or #result2 ~= 2 then
_G.checkError = "Лишние пробелы должны игнорироваться"
return false
end
if result2[1] ~= "show" or result2[2] ~= "all" then
_G.checkError = "Слова должны быть в нижнем регистре"
return false
end
local ok3, result3 = pcall(_G.ParseSlashArgs, "")
if not ok3 or type(result3) ~= "table" or #result3 ~= 0 then
_G.checkError = "Для пустой строки функция должна вернуть пустую таблицу"
return false
end
local ok4, result4 = pcall(_G.ParseSlashArgs, 123)
if not ok4 or type(result4) ~= "table" or #result4 ~= 0 then
_G.checkError = "Для не-строки функция должна вернуть пустую таблицу"
return false
end
return true
end,
}

ns_llua['lua'][273] = {
type = "commenttest",
title = "Тест 273: функция HandlePanelCommand",
helpModules = {269, 45, 17, 19},
preloadVars = {
{var = "HandlePanelCommand", desc = "HandlePanelCommand очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 245-4: функция HandlePanelCommand</h>
<t>Создай глобальную функцию <k>HandlePanelCommand(msg)</k>.</t>
<t>Требования:</t>
<t>- если <k>msg</k> не строка, верни строку <s>"invalid"</s>;</t>
<t>- приведи msg к нижнему регистру и убери пробелы по краям;</t>
<t>- если msg пустой или равен <s>"help"</s>, верни <s>"help"</s>;</t>
<t>- если msg равен <s>"show"</s>, верни <s>"show"</s>;</t>
<t>- если msg равен <s>"hide"</s>, верни <s>"hide"</s>;</t>
<t>- если msg равен <s>"toggle"</s>, верни <s>"toggle"</s>;</t>
<t>- если msg равен <s>"reset"</s>, верни <s>"reset"</s>;</t>
<t>- во всех остальных случаях верни <s>"unknown"</s>.</t>
<t>Используй <k>string.lower</k>, <k>string.gsub</k> для удаления пробелов.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию HandlePanelCommand(msg)
]=],
requireKeywords = {
"HandlePanelCommand",
"function",
"string.lower",
"if",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.HandlePanelCommand) ~= "function" then
_G.checkError = "HandlePanelCommand не является глобальной функцией"
return false
end
local tests = {
{input = "show", expected = "show"},
{input = "SHOW", expected = "show"},
{input = "  show  ", expected = "show"},
{input = "hide", expected = "hide"},
{input = "toggle", expected = "toggle"},
{input = "reset", expected = "reset"},
{input = "", expected = "help"},
{input = "help", expected = "help"},
{input = "  ", expected = "help"},
{input = "badcmd", expected = "unknown"},
{input = 123, expected = "invalid"},
{input = nil, expected = "invalid"},
}
for i, test in ipairs(tests) do
local ok, result = pcall(_G.HandlePanelCommand, test.input)
if not ok or result ~= test.expected then
_G.checkError = "Тест " .. i .. " не пройден (вход: " .. tostring(test.input) .. ")"
return false
end
end
return true
end,
}

ns_llua['lua'][274] = {
type = "commenttest",
title = "Тест 274: полный обработчик слэш-команды",
helpModules = {269, 215, 45, 31},
preloadVars = {
{var = "nsSlashPanel", desc = "nsSlashPanel очищается перед проверкой"},
{var = "nsSlashPanelState", desc = "nsSlashPanelState очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError", "nsSlashPanelState"},
instruction = [=[
<h>Тест 245-5: полный обработчик слэш-команды</h>
<t>Создай:</t>
<t>1. Глобальную таблицу <k>nsSlashPanelState</k> с полем <k>visible</k> равным <k>true</k>.</t>
<t>2. Глобальный фрейм <k>nsSlashPanel</k> (Frame, 200x100, CENTER, показан).</t>
<t>3. Глобальную переменную <k>SLASH_NSPANEL1</k> = <s>"/nspanel"</s>.</t>
<t>4. Обработчик <k>SlashCmdList["NSPANEL"]</k>, который:</t>
<t>- парсит msg в нижнем регистре;</t>
<t>- если <s>"show"</s>: показывает фрейм, ставит visible = true;</t>
<t>- если <s>"hide"</s>: скрывает фрейм, ставит visible = false;</t>
<t>- если <s>"toggle"</s>: переключает видимость;</t>
<t>- если <s>"reset"</s>: SetPoint("CENTER"), visible = true, Show();</t>
<t>- иначе: ничего не делает.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай nsSlashPanelState, nsSlashPanel и обработчик /nspanel
]=],
requireKeywords = {
"nsSlashPanelState",
"nsSlashPanel",
"SLASH_NSPANEL1",
"SlashCmdList",
"NSPANEL",
"function",
"Show",
"Hide",
},
checkCode = function()
_G.checkError = nil
if type(_G.nsSlashPanelState) ~= "table" then
_G.checkError = "nsSlashPanelState должна быть таблицей"
return false
end
if _G.nsSlashPanelState.visible ~= true then
_G.checkError = "nsSlashPanelState.visible должна быть true изначально"
return false
end
local f = _G.nsSlashPanel
if not f or type(f.IsShown) ~= "function" then
_G.checkError = "nsSlashPanel не является фреймом"
return false
end
if not f:IsShown() then
_G.checkError = "nsSlashPanel должен быть показан изначально"
return false
end
if _G.SLASH_NSPANEL1 ~= "/nspanel" then
_G.checkError = "SLASH_NSPANEL1 должна быть '/nspanel'"
return false
end
local handler = SlashCmdList["NSPANEL"]
if type(handler) ~= "function" then
_G.checkError = "SlashCmdList['NSPANEL'] должна быть функцией"
return false
end
-- Тест hide
local ok1, err1 = pcall(handler, "hide")
if not ok1 then
_G.checkError = "Ошибка при вызове 'hide': " .. tostring(err1)
return false
end
if _G.nsSlashPanelState.visible ~= false then
_G.checkError = "После 'hide' visible должна быть false"
return false
end
if f:IsShown() then
_G.checkError = "После 'hide' фрейм должен быть скрыт"
return false
end
-- Тест show
local ok2, err2 = pcall(handler, "show")
if not ok2 then
_G.checkError = "Ошибка при вызове 'show': " .. tostring(err2)
return false
end
if _G.nsSlashPanelState.visible ~= true then
_G.checkError = "После 'show' visible должна быть true"
return false
end
if not f:IsShown() then
_G.checkError = "После 'show' фрейм должен быть показан"
return false
end
-- Тест toggle
local ok3, err3 = pcall(handler, "toggle")
if not ok3 then
_G.checkError = "Ошибка при вызове 'toggle': " .. tostring(err3)
return false
end
if _G.nsSlashPanelState.visible ~= false then
_G.checkError = "После 'toggle' visible должна быть false"
return false
end
return true
end,
}

ns_llua['lua'][275] = {
type = "info",
title = "Кнопка на миникарте",
helpModules = {215, 221, 227, 233, 239},
content = [=[
<h>Кнопка на миникарте</h>
<t>Многие аддоны добавляют иконку на миникарту для быстрого доступа к настройкам или переключения видимости. В WoW 3.3.5 это делается вручную через позиционирование фрейма вокруг миникарты.</t>
<h>Миникарта как ориентир</h>
<t>Глобальный фрейм <k>Minimap</k> — это миникарта. Её размер обычно 140x140 пикселей.</t>
<code>
/run print(Minimap:GetWidth(), Minimap:GetHeight())
</code>
<h>Позиционирование по кругу</h>
<t>Чтобы разместить кнопку вокруг миникарты, используют тригонометрию:</t>
<code>
local angle = math.rad(45) -- угол в радианах
local radius = 80          -- радиус от центра
local x = math.cos(angle) * radius
local y = math.sin(angle) * radius
MyMinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
</code>
<t>Угол 0 — справа, 90 — сверху, 180 — слева, 270 — снизу.</t>
<h>Создание кнопки миникарты</h>
<code>
CourseMinimapBtn = CreateFrame("Button", "CourseMinimapBtn", Minimap)
CourseMinimapBtn:SetSize(32, 32)
CourseMinimapBtn:SetFrameStrata("HIGH")
CourseMinimapBtn:SetPoint("CENTER", Minimap, "CENTER", 80, 0)
</code>
<t>Обрати внимание: родитель — <k>Minimap</k>, а не <k>UIParent</k>. Это позволяет кнопке двигаться вместе с миникартой.</t>
<h>Иконка кнопки</h>
<code>
local icon = CourseMinimapBtn:CreateTexture(nil, "BACKGROUND")
icon:SetAllPoints(CourseMinimapBtn)
icon:SetTexture("Interface\\Icons\\Spell_Frost_IceStorm")
</code>
<h>Рамка (border)</h>
<t>Стандартная круглая рамка миникарты:</t>
<code>
local border = CourseMinimapBtn:CreateTexture(nil, "OVERLAY")
border:SetSize(54, 54)
border:SetPoint("CENTER", CourseMinimapBtn, "CENTER")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
</code>
<h>Перетаскивание по кругу миникарты</h>
<t>Чтобы кнопка двигалась только по окружности вокруг миникарты:</t>
<code>
CourseMinimapBtn:RegisterForDrag("LeftButton")
CourseMinimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function(self)
        local cx, cy = Minimap:GetCenter()
        local mx, my = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        mx = mx / scale
        my = my / scale
        local angle = math.atan2(my - cy, mx - cx)
        local radius = 80
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        self:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end)
end)
CourseMinimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)
</code>
<h>math.atan2</h>
<code>
/run print(math.atan2(1, 0))  -- pi/2 (90 градусов)
/run print(math.atan2(0, 1))  -- 0 (0 градусов)
</code>
<t>Функция <k>math.atan2(y, x)</k> возвращает угол в радианах от -pi до pi.</t>
<h>GetCursorPosition</h>
<t>Возвращает позицию курсора в пикселях экрана. Нужно делить на <k>GetEffectiveScale()</k> фрейма, чтобы получить координаты в масштабе фрейма.</t>
<h>Сохранение позиции</h>
<t>Угол кнопки удобно сохранять в SavedVariables:</t>
<code>
MyAddonDB = MyAddonDB or {}
MyAddonDB.minimapAngle = MyAddonDB.minimapAngle or 0
</code>
<t>При загрузке аддона восстанавливаем позицию:</t>
<code>
local angle = MyAddonDB.minimapAngle
local x = math.cos(angle) * 80
local y = math.sin(angle) * 80
CourseMinimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
</code>
<h>Частые ошибки</h>
<w>Ошибка 1:</w> родитель UIParent вместо Minimap. Кнопка не будет двигаться с миникартой.
<w>Ошибка 2:</w> забыть GetEffectiveScale при работе с GetCursorPosition.
<w>Ошибка 3:</w> не снять OnUpdate в OnDragStop. Кнопка продолжит двигаться после отпускания мыши.
]=],
}

ns_llua['lua'][276] = {
type = "vartest",
title = "Тест: тригонометрия для миникарты",
helpModules = {275, 10},
tasks = {
{
var = "minimapRadius",
desc = 'Создай глобальную переменную minimapRadius = 80',
check = function(value)
return type(value) == "number" and value == 80
end,
},
{
var = "angleRight",
desc = 'Создай глобальную переменную angleRight = 0 (угол в радианах для позиции справа)',
check = function(value)
return type(value) == "number" and value == 0
end,
},
{
var = "posXRight",
desc = 'Создай глобальную переменную posXRight = math.cos(0) * 80',
check = function(value)
return type(value) == "number" and math.abs(value - 80) < 0.01
end,
},
{
var = "posYRight",
desc = 'Создай глобальную переменную posYRight = math.sin(0) * 80',
check = function(value)
return type(value) == "number" and math.abs(value) < 0.01
end,
},
},
}

ns_llua['lua'][277] = {
type = "commenttest",
title = "Тест: кнопка на миникарте",
helpModules = {275, 215, 227},
preloadVars = {
{var = "CourseMinimapButton", desc = "CourseMinimapButton очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 251-2: кнопка на миникарте</h>
<t>Создай глобальную кнопку <k>CourseMinimapButton</k>.</t>
<t>Требования:</t>
<t>- тип: <s>"Button"</s>, глобальное имя: <s>"CourseMinimapButton"</s>;</t>
<t>- родитель: <k>Minimap</k>;</t>
<t>- размер: 32 на 32;</t>
<t>- слой: <k>SetFrameStrata("HIGH")</k>;</t>
<t>- позиция: <k>SetPoint("CENTER", Minimap, "CENTER", 80, 0)</k>;</t>
<t>- создай текстуру слоем BACKGROUND, растяни через SetAllPoints;</t>
<t>- установи текстуру: <s>"Interface\\Icons\\Spell_Frost_IceStorm"</s>;</t>
<t>- включи мышку через EnableMouse(true);</t>
<t>- покажи кнопку.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную кнопку CourseMinimapButton на миникарте
]=],
requireKeywords = {
"CourseMinimapButton",
"CreateFrame",
"Button",
"Minimap",
"SetSize",
"SetPoint",
"SetFrameStrata",
"CreateTexture",
"SetTexture",
"EnableMouse",
"Show",
},
checkCode = function()
_G.checkError = nil
local btn = _G.CourseMinimapButton
if not btn or type(btn.GetScript) ~= "function" then
_G.checkError = "CourseMinimapButton не является кнопкой"
return false
end
if not btn:IsShown() then
_G.checkError = "Кнопка должна быть показана"
return false
end
if btn:GetWidth() ~= 32 or btn:GetHeight() ~= 32 then
_G.checkError = "Размер кнопки должен быть 32 на 32"
return false
end
if btn:GetParent() ~= Minimap then
_G.checkError = "Родитель кнопки должен быть Minimap"
return false
end
return true
end,
}

ns_llua['lua'][278] = {
type = "commenttest",
title = "Тест: функция PositionOnMinimap",
helpModules = {275, 45, 10, 65},
preloadVars = {
{var = "PositionOnMinimap", desc = "PositionOnMinimap очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 251-3: функция PositionOnMinimap</h>
<t>Создай глобальную функцию <k>PositionOnMinimap(frame, angleDegrees, radius)</k>.</t>
<t>Требования:</t>
<t>- если <k>frame</k> не существует или у него нет метода <k>SetPoint</k>, верни <k>false</k>;</t>
<t>- если <k>angleDegrees</k> не число, верни <k>false</k>;</t>
<t>- если <k>radius</k> не число или меньше 10, верни <k>false</k>;</t>
<t>- иначе переведи градусы в радианы: <k>math.rad(angleDegrees)</k>;</t>
<t>- вычисли x = math.cos(radians) * radius;</t>
<t>- вычисли y = math.sin(radians) * radius;</t>
<t>- вызови <k>frame:SetPoint("CENTER", Minimap, "CENTER", x, y)</k>;</t>
<t>- верни <k>true</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию PositionOnMinimap(frame, angleDegrees, radius)
]=],
requireKeywords = {
"PositionOnMinimap",
"function",
"math.rad",
"math.cos",
"math.sin",
"SetPoint",
"Minimap",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.PositionOnMinimap) ~= "function" then
_G.checkError = "PositionOnMinimap не является глобальной функцией"
return false
end
local testFrame = CreateFrame("Frame", nil, Minimap)
testFrame:SetSize(32, 32)
local ok1, result1 = pcall(_G.PositionOnMinimap, testFrame, 45, 80)
if not ok1 then
_G.checkError = "Ошибка вызова PositionOnMinimap: " .. tostring(result1)
return false
end
if result1 ~= true then
_G.checkError = "Для корректных данных функция должна вернуть true"
return false
end
local ok2, result2 = pcall(_G.PositionOnMinimap, nil, 45, 80)
if not ok2 or result2 ~= false then
_G.checkError = "Для nil-фрейма функция должна вернуть false"
return false
end
local ok3, result3 = pcall(_G.PositionOnMinimap, testFrame, "bad", 80)
if not ok3 or result3 ~= false then
_G.checkError = "Для нечислового угла функция должна вернуть false"
return false
end
local ok4, result4 = pcall(_G.PositionOnMinimap, testFrame, 45, 5)
if not ok4 or result4 ~= false then
_G.checkError = "Для radius < 10 функция должна вернуть false"
return false
end
return true
end,
}

ns_llua['lua'][279] = {
type = "commenttest",
title = "Тест: функция CreateMinimapButton",
helpModules = {275, 215, 227, 233, 45, 65},
preloadVars = {
{var = "CreateMinimapButton", desc = "CreateMinimapButton очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 251-4: функция CreateMinimapButton</h>
<t>Создай глобальную функцию <k>CreateMinimapButton(name, texturePath, angle)</k>.</t>
<t>Требования:</t>
<t>- если <k>name</k> не строка или пустая, верни <k>nil</k>;</t>
<t>- если <k>texturePath</k> не строка или пустая, верни <k>nil</k>;</t>
<t>- если <k>angle</k> не число, используй <n>0</n>;</t>
<t>- создай кнопку типа <s>"Button"</s> с именем <k>name</k>, родитель <k>Minimap</k>;</t>
<t>- размер: 32 на 32;</t>
<t>- слой: HIGH;</t>
<t>- создай текстуру BACKGROUND, SetAllPoints, SetTexture(texturePath);</t>
<t>- создай текстуру OVERLAY для рамки: размер 54x54, CENTER, текстура <s>"Interface\\Minimap\\MiniMap-TrackingBorder"</s>;</t>
<t>- вычисли позицию: x = cos(rad(angle)) * 80, y = sin(rad(angle)) * 80;</t>
<t>- SetPoint("CENTER", Minimap, "CENTER", x, y);</t>
<t>- EnableMouse(true);</t>
<t>- покажи кнопку;</t>
<t>- верни кнопку.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CreateMinimapButton(name, texturePath, angle)
]=],
requireKeywords = {
"CreateMinimapButton",
"function",
"CreateFrame",
"Button",
"Minimap",
"CreateTexture",
"SetTexture",
"math.cos",
"math.sin",
"math.rad",
"SetPoint",
"Show",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CreateMinimapButton) ~= "function" then
_G.checkError = "CreateMinimapButton не является глобальной функцией"
return false
end
local ok1, btn = pcall(_G.CreateMinimapButton, "NS_MM_Btn_1", "Interface\\Icons\\Spell_Frost_IceStorm", 45)
if not ok1 then
_G.checkError = "Ошибка вызова CreateMinimapButton: " .. tostring(btn)
return false
end
if not btn or type(btn.GetScript) ~= "function" then
_G.checkError = "Функция должна вернуть кнопку"
return false
end
if not btn:IsShown() then
_G.checkError = "Кнопка должна быть показана"
return false
end
if btn:GetParent() ~= Minimap then
_G.checkError = "Родитель должен быть Minimap"
return false
end
if btn:GetWidth() ~= 32 or btn:GetHeight() ~= 32 then
_G.checkError = "Размер кнопки должен быть 32 на 32"
return false
end
local ok2, result2 = pcall(_G.CreateMinimapButton, "", "Interface\\Icons\\Test", 0)
if not ok2 or result2 ~= nil then
_G.checkError = "Для пустого имени функция должна вернуть nil"
return false
end
local ok3, result3 = pcall(_G.CreateMinimapButton, "NS_MM_Btn_2", "", 0)
if not ok3 or result3 ~= nil then
_G.checkError = "Для пустой текстуры функция должна вернуть nil"
return false
end
return true
end,
}

ns_llua['lua'][280] = {
type = "commenttest",
title = "Тест: кнопка миникарты с перетаскиванием",
helpModules = {275, 221, 233, 45},
preloadVars = {
{var = "CourseDragMinimapBtn", desc = "CourseDragMinimapBtn очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {"checkError"},
instruction = [=[
<h>Тест 251-5: кнопка миникарты с перетаскиванием</h>
<t>Создай глобальную кнопку <k>CourseDragMinimapBtn</k>.</t>
<t>Требования:</t>
<t>- тип: <s>"Button"</s>, родитель: <k>Minimap</k>;</t>
<t>- размер: 32 на 32, слой HIGH;</t>
<t>- позиция: CENTER, Minimap, CENTER, 80, 0;</t>
<t>- текстура BACKGROUND: <s>"Interface\\Icons\\Inv_Sword_04"</s>, SetAllPoints;</t>
<t>- EnableMouse(true);</t>
<t>- RegisterForDrag("LeftButton");</t>
<t>- скрипт <k>OnDragStart</k>: назначает OnUpdate, который:</t>
<c>получает центр Minimap через GetCenter()</c>
<c>получает позицию курсора через GetCursorPosition()</c>
<c>делит на GetEffectiveScale()</c>
<c>вычисляет angle через math.atan2</c>
<c>вычисляет x, y через cos/sin с radius 80</c>
<c>вызывает SetPoint("CENTER", Minimap, "CENTER", x, y)</c>
<t>- скрипт <k>OnDragStop</k>: снимает OnUpdate через SetScript("OnUpdate", nil);</t>
<t>- покажи кнопку.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную кнопку CourseDragMinimapBtn с перетаскиванием по миникарте
]=],
requireKeywords = {
"CourseDragMinimapBtn",
"CreateFrame",
"Button",
"Minimap",
"EnableMouse",
"RegisterForDrag",
"OnDragStart",
"OnDragStop",
"OnUpdate",
"GetCenter",
"GetCursorPosition",
"GetEffectiveScale",
"math.atan2",
"math.cos",
"math.sin",
"SetPoint",
},
checkCode = function()
_G.checkError = nil
local btn = _G.CourseDragMinimapBtn
if not btn or type(btn.GetScript) ~= "function" then
_G.checkError = "CourseDragMinimapBtn не является кнопкой"
return false
end
if not btn:IsShown() then
_G.checkError = "Кнопка должна быть показана"
return false
end
if btn:GetParent() ~= Minimap then
_G.checkError = "Родитель должен быть Minimap"
return false
end
local onDragStart = btn:GetScript("OnDragStart")
if type(onDragStart) ~= "function" then
_G.checkError = "У кнопки должен быть OnDragStart"
return false
end
local onDragStop = btn:GetScript("OnDragStop")
if type(onDragStop) ~= "function" then
_G.checkError = "У кнопки должен быть OnDragStop"
return false
end
return true
end,
}

















































ns_llua['lua'][281] = {
type = "info",
title = "Таланты: вкладки и очки",
helpModules = {65, 45, 31},
content = [=[
<h>Таланты: вкладки и очки</h>
<t>Система талантов в WoW 3.3.5 позволяет настраивать специализацию персонажа. У каждого класса есть три ветки талантов.</t>
<h>GetNumTalentTabs</h>
<code>
/run print(GetNumTalentTabs())
</code>
<t>Возвращает количество вкладок талантов. Обычно это <n>3</n>.</t>
<h>GetNumTalents</h>
<code>
/run print(GetNumTalents(1))
</code>
<t>Возвращает количество талантов на указанной вкладке.</t>
<t>Аргументы:</t>
<c>1</c> — номер вкладки (1, 2 или 3).
<c>false</c> — второй аргумент, если нужно считать только доступные таланты.
<h>GetTalentInfo</h>
<code>
/run local name, rank, maxRank = GetTalentInfo(1, 1); print(name, rank, maxRank)
</code>
<t>Возвращает информацию о таланте:</t>
<c>name</c> — название таланта.
<c>rank</c> — текущий ранг.
<c>maxRank</c> — максимальный ранг.
<c>isExceptional</c> — является ли талантом исключительным.
<c>meetsPrereq</c> — выполнены ли требования.
<h>GetUnspentTalentPoints</h>
<code>
/run print(GetUnspentTalentPoints())
</code>
<t>Возвращает количество неиспользованных очков талантов.</t>
<h>GetNumTalentGroups</h>
<code>
/run print(GetNumTalentGroups())
</code>
<t>Возвращает количество наборов талантов. Обычно <n>1</n> или <n>2</n> (если куплен второй набор).</t>
<h>GetActiveTalentGroup</h>
<code>
/run print(GetActiveTalentGroup())
</code>
<t>Возвращает номер активного набора талантов: <n>1</n> или <n>2</n>.</t>
<h>Перебор талантов</h>
<code>
/run local count = GetNumTalents(1); for i = 1, count do local name, rank, maxRank = GetTalentInfo(1, i); if rank > 0 then print(name, rank .. "/" .. maxRank) end end
</code>
<h>Подсчёт вложенных очков</h>
<code>
/run local total = 0; for tab = 1, 3 do local count = GetNumTalents(tab); for i = 1, count do local _, rank = GetTalentInfo(tab, i); total = total + (rank or 0) end end; print("Всего очков: " .. total)
</code>
<w>Важно:</w> если персонаж ещё не открыл таланты или данные ещё не загружены, некоторые функции могут вернуть <k>nil</k>.
<h>Безопасный шаблон</h>
<code>
/run local points = GetUnspentTalentPoints() or 0; print("Неиспользованных очков: " .. points)
</code>
]=],
}

ns_llua['lua'][282] = {
type = "vartest",
title = "Тест: количество вкладок и очков",
helpModules = {281, 65},
tasks = {
{
var = "talentTabCount",
desc = 'Создай глобальную переменную talentTabCount = GetNumTalentTabs() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "unspentTalentPoints",
desc = 'Создай глобальную переменную unspentTalentPoints = GetUnspentTalentPoints() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][283] = {
type = "vartest",
title = "Тест: активный набор талантов",
helpModules = {281, 65},
tasks = {
{
var = "talentGroupCount",
desc = 'Создай глобальную переменную talentGroupCount = GetNumTalentGroups() or 1',
check = function(value)
return type(value) == "number" and value >= 1
end,
},
{
var = "activeTalentGroup",
desc = 'Создай глобальную переменную activeTalentGroup = GetActiveTalentGroup() or 1',
check = function(value)
return type(value) == "number" and value >= 1
end,
},
},
}

ns_llua['lua'][284] = {
type = "commenttest",
title = "Тест: функция GetTalentTabCountSafe",
helpModules = {281, 45, 65},
preloadVars = {
{var = "GetTalentTabCountSafe", desc = "GetTalentTabCountSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 257-3: функция GetTalentTabCountSafe</h>
<t>Создай глобальную функцию <k>GetTalentTabCountSafe()</k>.</t>
<t>Функция должна вернуть количество вкладок талантов через:</t>
<code>
GetNumTalentTabs()
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть количество вкладок.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetTalentTabCountSafe()
]=],
requireKeywords = {
"GetTalentTabCountSafe",
"function",
"GetNumTalentTabs",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetTalentTabCountSafe) ~= "function" then
_G.checkError = "GetTalentTabCountSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetTalentTabCountSafe)
if not ok then
_G.checkError = "Ошибка вызова GetTalentTabCountSafe: " .. tostring(result)
return false
end
if type(result) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if result < 0 then
_G.checkError = "Количество вкладок талантов не может быть отрицательным"
return false
end
return true
end,
}

ns_llua['lua'][285] = {
type = "commenttest",
title = "Тест: функция GetActiveTalentGroupSafe",
helpModules = {281, 45, 65},
preloadVars = {
{var = "GetActiveTalentGroupSafe", desc = "GetActiveTalentGroupSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 257-4: функция GetActiveTalentGroupSafe</h>
<t>Создай глобальную функцию <k>GetActiveTalentGroupSafe()</k>.</t>
<t>Функция должна вернуть номер активного набора талантов через:</t>
<code>
GetActiveTalentGroup()
</code>
<t>Если результат не является числом или меньше единицы, функция должна вернуть <n>1</n>.</t>
<t>Иначе функция должна вернуть номер активного набора.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetActiveTalentGroupSafe()
]=],
requireKeywords = {
"GetActiveTalentGroupSafe",
"function",
"GetActiveTalentGroup",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetActiveTalentGroupSafe) ~= "function" then
_G.checkError = "GetActiveTalentGroupSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetActiveTalentGroupSafe)
if not ok then
_G.checkError = "Ошибка вызова GetActiveTalentGroupSafe: " .. tostring(result)
return false
end
if type(result) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if result < 1 then
_G.checkError = "Номер активного набора талантов должен быть не меньше 1"
return false
end
return true
end,
}

ns_llua['lua'][286] = {
type = "commenttest",
title = "Тест: функция CountTalentsInTab",
helpModules = {281, 45, 31, 65},
preloadVars = {
{var = "CountTalentsInTab", desc = "CountTalentsInTab очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 257-5: функция CountTalentsInTab</h>
<t>Создай глобальную функцию <k>CountTalentsInTab(tab)</k>.</t>
<t>Если <k>tab</k> не является числом, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть количество талантов на вкладке через:</t>
<code>
GetNumTalents(tab)
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть количество талантов.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CountTalentsInTab(tab)
]=],
requireKeywords = {
"CountTalentsInTab",
"function",
"GetNumTalents",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CountTalentsInTab) ~= "function" then
_G.checkError = "CountTalentsInTab не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.CountTalentsInTab, 1)
if not ok1 then
_G.checkError = "Ошибка вызова CountTalentsInTab(1): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < 0 then
_G.checkError = "Для tab = 1 функция должна вернуть число больше или равное нулю"
return false
end
local ok2, result2 = pcall(_G.CountTalentsInTab, -1)
if not ok2 or result2 ~= 0 then
_G.checkError = "Для tab = -1 функция должна вернуть 0"
return false
end
local ok3, result3 = pcall(_G.CountTalentsInTab, "bad")
if not ok3 or result3 ~= 0 then
_G.checkError = "Для нечислового tab функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][287] = {
type = "info",
title = "Репутация фракций",
helpModules = {65, 45, 31},
content = [=[
<h>Репутация фракций</h>
<t>В WoW у игрока есть репутация с различными фракциями. Чем выше репутация, тем больше наград доступно.</t>
<w>Важно:</w> в списке репутации есть не только фракции, но и заголовки-категории. Их нужно отличать.
<h>GetNumFactions</h>
<code>
/run print(GetNumFactions())
</code>
<t>Возвращает общее количество записей в списке репутации. Это и фракции, и заголовки.</t>
<h>GetFactionInfo</h>
<code>
/run local name, desc, standingID, barMin, barMax, barValue = GetFactionInfo(1); print(name, standingID, barValue)
</code>
<t>Основные возвращаемые значения:</t>
<c>name</c> — название фракции или заголовка.
<c>description</c> — описание.
<c>standingID</c> — числовой уровень репутации.
<c>barMin</c> — минимальное значение полосы.
<c>barMax</c> — максимальное значение полосы.
<c>barValue</c> — текущее значение полосы.
<h>Уровни репутации (standingID)</h>
<c>1</c> — Ненависть (Hated).
<c>2</c> — Враждебность (Hostile).
<c>3</c> — Недружелюбие (Unfriendly).
<c>4</c> — Нейтралитет (Neutral).
<c>5</c> — Дружелюбие (Friendly).
<c>6</c> — Уважение (Honored).
<c>7</c> — Почтение (Revered).
<c>8</c> — Превознесение (Exalted).
<h>Заголовки и фракции</h>
<t>GetFactionInfo возвращает поле <k>isHeader</k>. Если оно истинно, это заголовок-категория, а не фракция.</t>
<code>
/run local name, _, _, _, _, _, _, _, isHeader = GetFactionInfo(1); print(name, isHeader)
</code>
<h>Отслеживаемая фракция</h>
<code>
/run local name, standingID, barMin, barMax, barValue = GetWatchedFactionInfo(); print(name or "Ничего не отслеживается")
</code>
<h>Перебор фракций</h>
<code>
/run local count = GetNumFactions() or 0; for i = 1, count do local name, _, standingID, _, _, _, _, _, isHeader = GetFactionInfo(i); if name and not isHeader then print(name, standingID) end end
</code>
<h>Безопасный шаблон</h>
<code>
/run local name = GetWatchedFactionInfo() or "Нет фракции"; print("Отслеживается: " .. name)
</code>
]=],
}

ns_llua['lua'][288] = {
type = "vartest",
title = "Тест: количество записей репутации",
helpModules = {287, 65},
tasks = {
{
var = "factionCount",
desc = 'Создай глобальную переменную factionCount = GetNumFactions() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "firstFactionName",
desc = 'Создай глобальную переменную firstFactionName = GetFactionInfo(1) or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "firstFactionStanding",
desc = 'Создай глобальную переменную firstFactionStanding = select(3, GetFactionInfo(1)) or 0',
check = function(value)
return type(value) == "number" and value >= 0 and value <= 8
end,
},
},
}

ns_llua['lua'][289] = {
type = "vartest",
title = "Тест: отслеживаемая фракция",
helpModules = {287, 65},
tasks = {
{
var = "watchedFactionName",
desc = 'Создай глобальную переменную watchedFactionName = GetWatchedFactionInfo() or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "watchedFactionStanding",
desc = 'Создай глобальную переменную watchedFactionStanding = select(2, GetWatchedFactionInfo()) or 0',
check = function(value)
return type(value) == "number" and value >= 0 and value <= 8
end,
},
{
var = "watchedFactionBarValue",
desc = 'Создай глобальную переменную watchedFactionBarValue = select(5, GetWatchedFactionInfo()) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][290] = {
type = "commenttest",
title = "Тест: функция GetFactionCountSafe",
helpModules = {287, 45, 65},
preloadVars = {
{var = "GetFactionCountSafe", desc = "GetFactionCountSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 263-3: функция GetFactionCountSafe</h>
<t>Создай глобальную функцию <k>GetFactionCountSafe()</k>.</t>
<t>Функция должна вернуть количество записей в списке репутации через:</t>
<code>
GetNumFactions()
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть количество записей.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetFactionCountSafe()
]=],
requireKeywords = {
"GetFactionCountSafe",
"function",
"GetNumFactions",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetFactionCountSafe) ~= "function" then
_G.checkError = "GetFactionCountSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetFactionCountSafe)
if not ok then
_G.checkError = "Ошибка вызова GetFactionCountSafe: " .. tostring(result)
return false
end
if type(result) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if result < 0 then
_G.checkError = "Количество записей не может быть отрицательным"
return false
end
return true
end,
}

ns_llua['lua'][291] = {
type = "commenttest",
title = "Тест: функция GetFactionNameSafe",
helpModules = {287, 45, 65},
preloadVars = {
{var = "GetFactionNameSafe", desc = "GetFactionNameSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 263-4: функция GetFactionNameSafe</h>
<t>Создай глобальную функцию <k>GetFactionNameSafe(index)</k>.</t>
<t>Если <k>index</k> не является числом или меньше либо равно нуля, функция должна вернуть строку:</t>
<s>"нет"</s>
<t>Иначе функция должна получить имя записи репутации через:</t>
<code>
GetFactionInfo(index)
</code>
<t>Если имя не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"нет"</s>
<t>Иначе функция должна вернуть имя записи.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetFactionNameSafe(index)
]=],
requireKeywords = {
"GetFactionNameSafe",
"function",
"GetFactionInfo",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetFactionNameSafe) ~= "function" then
_G.checkError = "GetFactionNameSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetFactionNameSafe, 1)
if not ok1 then
_G.checkError = "Ошибка вызова GetFactionNameSafe(1): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для index = 1 функция должна вернуть строку"
return false
end
local ok2, result2 = pcall(_G.GetFactionNameSafe, 0)
if not ok2 or result2 ~= "нет" then
_G.checkError = "Для index = 0 функция должна вернуть 'нет'"
return false
end
local ok3, result3 = pcall(_G.GetFactionNameSafe, "bad")
if not ok3 or result3 ~= "нет" then
_G.checkError = "Для нечислового index функция должна вернуть 'нет'"
return false
end
local ok4, result4 = pcall(_G.GetFactionNameSafe, 999999)
if not ok4 then
_G.checkError = "Ошибка вызова GetFactionNameSafe(999999): " .. tostring(result4)
return false
end
if result4 ~= "нет" then
_G.checkError = "Для несуществующего index функция должна вернуть 'нет'"
return false
end
return true
end,
}

ns_llua['lua'][292] = {
type = "commenttest",
title = "Тест: функция GetWatchedFactionNameSafe",
helpModules = {287, 45, 65},
preloadVars = {
{var = "GetWatchedFactionNameSafe", desc = "GetWatchedFactionNameSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 263-5: функция GetWatchedFactionNameSafe</h>
<t>Создай глобальную функцию <k>GetWatchedFactionNameSafe()</k>.</t>
<t>Функция должна вернуть имя отслеживаемой фракции через:</t>
<code>
GetWatchedFactionInfo()
</code>
<t>Если результат не является строкой или является пустой строкой, функция должна вернуть строку:</t>
<s>"нет"</s>
<t>Иначе функция должна вернуть имя отслеживаемой фракции.</t>
<t>Используй:</t>
<c>GetWatchedFactionInfo</c>
<c>type</c>
<c>return</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetWatchedFactionNameSafe()
]=],
requireKeywords = {
"GetWatchedFactionNameSafe",
"function",
"GetWatchedFactionInfo",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetWatchedFactionNameSafe) ~= "function" then
_G.checkError = "GetWatchedFactionNameSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetWatchedFactionNameSafe)
if not ok then
_G.checkError = "Ошибка вызова GetWatchedFactionNameSafe: " .. tostring(result)
return false
end
if type(result) ~= "string" or result == "" then
_G.checkError = "Функция должна вернуть непустую строку"
return false
end
return true
end,
}

ns_llua['lua'][293] = {
type = "info",
title = "Квесты: журнал и статусы",
helpModules = {65, 45, 31},
content = [=[
<h>Квесты: журнал и статусы</h>
<t>Журнал квестов содержит все активные квесты персонажа. Доступ к нему осуществляется через функции API.</t>
<w>Важно:</w> в WoW 3.3.5 нет прямой функции поиска квеста по ID. Для поиска нужно перебирать журнал вручную.
<h>GetNumQuestLogEntries</h>
<code>
/run print(GetNumQuestLogEntries())
</code>
<t>Возвращает количество записей в журнале квестов.</t>
<h>GetQuestLogTitle</h>
<code>
/run print(GetQuestLogTitle(1))
</code>
<t>Возвращает название квеста по индексу.</t>
<t>Если индекс неверный или квеста нет, функция может вернуть <k>nil</k>.</t>
<h>GetQuestLogLevel</h>
<code>
/run print(GetQuestLogLevel(1))
</code>
<t>Возвращает уровень квеста.</t>
<h>Перебор журнала квестов</h>
<code>
/run local count = GetNumQuestLogEntries() or 0; for i = 1, count do local title = GetQuestLogTitle(i); if title then print(i, title) end end
</code>
<h>GetQuestLogCompletionText</h>
<t>Возвращает текст завершения квеста, если квест готов к сдаче.</t>
<code>
/run print(GetQuestLogCompletionText() or "Квест не завершён")
</code>
<w>Примечание:</w> эта функция работает для текущего выбранного квеста. Для работы с конкретным квестом нужно сначала выбрать его через <k>SelectQuestLogEntry</k>.
<h>SelectQuestLogEntry</h>
<code>
/run SelectQuestLogEntry(1)
</code>
<t>Выбирает квест по индексу в журнале. После этого функции, работающие с текущим квестом, будут применяться к нему.</t>
<h>Подсчёт квестов по уровню</h>
<code>
/run local count = GetNumQuestLogEntries() or 0; local highLevel = 0; for i = 1, count do local level = GetQuestLogLevel(i); if level and level >= 70 then highLevel = highLevel + 1 end end; print("Квестов 70+: " .. highLevel)
</code>
<h>Безопасный шаблон</h>
<code>
/run local title = GetQuestLogTitle(1) or "Нет квеста"; print("Первый квест: " .. title)
</code>
]=],
}

ns_llua['lua'][294] = {
type = "vartest",
title = "Тест: количество квестов в журнале",
helpModules = {293, 65},
tasks = {
{
var = "questLogCount",
desc = 'Создай глобальную переменную questLogCount = GetNumQuestLogEntries() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][295] = {
type = "vartest",
title = "Тест: первый квест в журнале",
helpModules = {293, 65},
tasks = {
{
var = "firstQuestTitle",
desc = 'Создай глобальную переменную firstQuestTitle = GetQuestLogTitle(1) or "нет квеста"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "firstQuestLevel",
desc = 'Создай глобальную переменную firstQuestLevel = GetQuestLogLevel(1) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][296] = {
type = "commenttest",
title = "Тест: функция GetQuestLogCountSafe",
helpModules = {293, 45, 65},
preloadVars = {
{var = "GetQuestLogCountSafe", desc = "GetQuestLogCountSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 269-3: функция GetQuestLogCountSafe</h>
<t>Создай глобальную функцию <k>GetQuestLogCountSafe()</k>.</t>
<t>Функция должна вернуть количество записей в журнале квестов через:</t>
<code>
GetNumQuestLogEntries()
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть количество записей.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetQuestLogCountSafe()
]=],
requireKeywords = {
"GetQuestLogCountSafe",
"function",
"GetNumQuestLogEntries",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetQuestLogCountSafe) ~= "function" then
_G.checkError = "GetQuestLogCountSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetQuestLogCountSafe)
if not ok then
_G.checkError = "Ошибка вызова GetQuestLogCountSafe: " .. tostring(result)
return false
end
if type(result) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if result < 0 then
_G.checkError = "Количество квестов не может быть отрицательным"
return false
end
return true
end,
}

ns_llua['lua'][297] = {
type = "commenttest",
title = "Тест: функция GetQuestTitleSafe",
helpModules = {293, 45, 65},
preloadVars = {
{var = "GetQuestTitleSafe", desc = "GetQuestTitleSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 269-4: функция GetQuestTitleSafe</h>
<t>Создай глобальную функцию <k>GetQuestTitleSafe(index)</k>.</t>
<t>Если <k>index</k> не является числом или меньше либо равно нуля, функция должна вернуть строку:</t>
<s>"нет квеста"</s>
<t>Иначе функция должна получить название квеста через:</t>
<code>
GetQuestLogTitle(index)
</code>
<t>Если результат не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"нет квеста"</s>
<t>Иначе функция должна вернуть название квеста.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetQuestTitleSafe(index)
]=],
requireKeywords = {
"GetQuestTitleSafe",
"function",
"GetQuestLogTitle",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetQuestTitleSafe) ~= "function" then
_G.checkError = "GetQuestTitleSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetQuestTitleSafe, 1)
if not ok1 then
_G.checkError = "Ошибка вызова GetQuestTitleSafe(1): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для index = 1 функция должна вернуть строку"
return false
end
local ok2, result2 = pcall(_G.GetQuestTitleSafe, 0)
if not ok2 or result2 ~= "нет квеста" then
_G.checkError = "Для index = 0 функция должна вернуть 'нет квеста'"
return false
end
local ok3, result3 = pcall(_G.GetQuestTitleSafe, "bad")
if not ok3 or result3 ~= "нет квеста" then
_G.checkError = "Для нечислового index функция должна вернуть 'нет квеста'"
return false
end
return true
end,
}

ns_llua['lua'][298] = {
type = "commenttest",
title = "Тест: функция FindQuestInLog",
helpModules = {293, 45, 31, 33, 65},
preloadVars = {
{var = "FindQuestInLog", desc = "FindQuestInLog очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 269-5: функция FindQuestInLog</h>
<t>Создай глобальную функцию <k>FindQuestInLog(text)</k>.</t>
<t>Если <k>text</k> не является строкой или является пустой строкой, функция должна вернуть <k>nil</k>.</t>
<t>Иначе функция должна перебрать все записи журнала квестов и найти первый квест, в названии которого есть подстрока <k>text</k>.</t>
<t>Алгоритм:</t>
<t>1. Получи количество записей через <k>GetNumQuestLogEntries()</k>.</t>
<t>2. Перебери индексы от 1 до количества.</t>
<t>3. Для каждого индекса получи название через <k>GetQuestLogTitle(index)</k>.</t>
<t>4. Если название содержит подстроку <k>text</k>, верни индекс этого квеста.</t>
<t>5. Если ничего не найдено, верни <k>nil</k>.</t>
<t>Используй:</t>
<c>GetNumQuestLogEntries</c>
<c>GetQuestLogTitle</c>
<c>string.find</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию FindQuestInLog(text)
]=],
requireKeywords = {
"FindQuestInLog",
"function",
"GetNumQuestLogEntries",
"GetQuestLogTitle",
"string.find",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.FindQuestInLog) ~= "function" then
_G.checkError = "FindQuestInLog не является глобальной функцией"
return false
end
-- Тест 1: пустая строка
local ok1, result1 = pcall(_G.FindQuestInLog, "")
if not ok1 or result1 ~= nil then
_G.checkError = "Для пустой строки функция должна вернуть nil"
return false
end
-- Тест 2: не строка
local ok2, result2 = pcall(_G.FindQuestInLog, 123)
if not ok2 or result2 ~= nil then
_G.checkError = "Для нестрокового аргумента функция должна вернуть nil"
return false
end
-- Тест 3: несуществующая подстрока
local ok3, result3 = pcall(_G.FindQuestInLog, "zzz_no_such_quest_zzz")
if not ok3 then
_G.checkError = "Ошибка вызова FindQuestInLog с несуществующей строкой: " .. tostring(result3)
return false
end
if result3 ~= nil then
_G.checkError = "Для несуществующей подстроки функция должна вернуть nil"
return false
end
return true
end,
}

ns_llua['lua'][299] = {
type = "info",
title = "Парсинг ссылок предметов",
helpModules = {179, 33, 65},
content = [=[
<h>Парсинг ссылок предметов</h>
<t>В WoW предметы часто представлены в виде строк-ссылок. Такие ссылки используются в чате, тултипах и интерфейсе.</t>
<h>Как выглядит ссылка на предмет</h>
<code>
/run local name, link = GetItemInfo(6948); print(link)
</code>
<t>Типичная ссылка выглядит так:</t>
<code>
|cffA335EE|Hitem:6948:0:0:0:0:0:0:0|h[Камень возвращения]|h|r
</code>
<t>Разберём структуру:</t>
<c>|cffA335EE</c> — цвет качества предмета в hex.
<c>|Hitem:6948:0:0:0:0:0:0:0|h</c> — гиперссылка с ID предмета и параметрами.
<c>[Камень возвращения]</c> — название предмета в квадратных скобках.
<c>|h|r</c> — закрытие гиперссылки и сброс цвета.
<h>Цвета качества</h>
<c>9d9d9d</c> — бедный (0).
<c>ffffff</c> — обычный (1).
<c>1eff00</c> — необычный (2).
<c>0070dd</c> — редкий (3).
<c>a335ee</c> — эпический (4).
<c>ff8000</c> — легендарный (5).
<h>Получение ссылки на предмет</h>
<t>Ссылку можно получить через GetItemInfo:</t>
<code>
/run local name, link = GetItemInfo(6948); print(link or "нет ссылки")
</code>
<t>Или через сумку:</t>
<code>
/run print(GetContainerItemLink(0, 1) or "пусто")
</code>
<h>Парсинг через string.match</h>
<t>Функция string.match позволяет извлекать части строки по паттерну.</t>
<h>Извлечение ID предмета</h>
<code>
/run local name, link = GetItemInfo(6948); if link then local id = link:match("|Hitem:(%d+)"); print("ID: " .. tostring(id)) end
</code>
<t>Паттерн <k>|Hitem:(%d+)</k> ищет подстроку после <s>|Hitem:</s> и захватывает цифры в скобки.</t>
<w>Важно:</w> в Lua паттернах круглые скобки <k>()</k> означают захват, а <k>%d</k> означает цифру. Знак <k>+</k> означает один или более символов.
<h>Извлечение названия</h>
<code>
/run local name, link = GetItemInfo(6948); if link then local itemName = link:match("%[(.+)%]"); print("Название: " .. tostring(itemName)) end
</code>
<t>Паттерн <k>%[(.+)%]</k> ищет текст между квадратными скобками.</t>
<h>Извлечение цвета</h>
<code>
/run local name, link = GetItemInfo(6948); if link then local color = link:match("|cff(%x%x%x%x%x%x)"); print("Цвет: " .. tostring(color)) end
</code>
<t>Паттерн <k>|cff(%x%x%x%x%x%x)</k> захватывает 6 шестнадцатеричных символов после <s>|cff</s>.</t>
<h>Ссылки на заклинания</h>
<t>Ссылки на заклинания имеют другой формат:</t>
<code>
|cff71d5ff|Hspell:6603|h[Название заклинания]|h|r
</code>
<t>Здесь вместо <s>item</s> используется <s>spell</s>.</t>
<h>Безопасный шаблон</h>
<code>
/run local name, link = GetItemInfo(6948); if link then local id = link:match("|Hitem:(%d+)"); print("ID: " .. (id or "нет")) else print("Ссылки нет") end
</code>
<w>Примечание:</w> если предмет ещё не загружен в кэш, GetItemInfo может вернуть nil для ссылки. Поэтому всегда проверяй результат.
]=],
}

ns_llua['lua'][300] = {
type = "vartest",
title = "Тест: ссылка на камень возвращения",
helpModules = {299, 179, 65},
tasks = {
{
var = "hearthstoneLink",
desc = 'Создай глобальную переменную hearthstoneLink = select(2, GetItemInfo(6948)) or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "hearthstoneLinkIsString",
desc = 'Создай глобальную переменную hearthstoneLinkIsString = type(select(2, GetItemInfo(6948)) or "нет") == "string"',
check = function(value)
return type(value) == "boolean" and value == true
end,
},
},
}

ns_llua['lua'][301] = {
type = "vartest",
title = "Тест: парсинг ссылки",
helpModules = {299, 33, 65},
tasks = {
{
var = "hearthstoneItemID",
desc = 'Создай глобальную переменную hearthstoneItemID: извлеки ID предмета из ссылки камня возвращения через string.match и паттерн "|Hitem:(%d+)". Если ссылки нет, используй 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "hearthstoneColor",
desc = 'Создай глобальную переменную hearthstoneColor: извлеки цвет качества из ссылки камня возвращения через string.match и паттерн "|cff(%x%x%x%x%x%x)". Если ссылки нет, используй "ffffff"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "hearthstoneBracketName",
desc = 'Создай глобальную переменную hearthstoneBracketName: извлеки название из квадратных скобок ссылки камня возвращения через string.match и паттерн "%[(.+)%]". Если ссылки нет, используй "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
},
}

ns_llua['lua'][302] = {
type = "commenttest",
title = "Тест: функция ExtractItemIDFromLink",
helpModules = {299, 33, 45, 65},
preloadVars = {
{var = "ExtractItemIDFromLink", desc = "ExtractItemIDFromLink очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 275-3: функция ExtractItemIDFromLink</h>
<t>Создай глобальную функцию <k>ExtractItemIDFromLink(link)</k>.</t>
<t>Если <k>link</k> не является строкой или является пустой строкой, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна извлечь ID предмета из ссылки через:</t>
<code>
link:match("|Hitem:(%d+)")
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть ID предмета как число.</t>
<t>Используй <k>tonumber</k> для преобразования строки в число.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию ExtractItemIDFromLink(link)
]=],
requireKeywords = {
"ExtractItemIDFromLink",
"function",
"string.match",
"tonumber",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.ExtractItemIDFromLink) ~= "function" then
_G.checkError = "ExtractItemIDFromLink не является глобальной функцией"
return false
end
-- Тест 1: реальная ссылка камня возвращения
local _, realLink = GetItemInfo(6948)
if realLink then
local ok1, result1 = pcall(_G.ExtractItemIDFromLink, realLink)
if not ok1 then
_G.checkError = "Ошибка вызова ExtractItemIDFromLink с реальной ссылкой: " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 ~= 6948 then
_G.checkError = "Для ссылки камня возвращения функция должна вернуть 6948"
return false
end
end
-- Тест 2: пустая строка
local ok2, result2 = pcall(_G.ExtractItemIDFromLink, "")
if not ok2 or result2 ~= 0 then
_G.checkError = "Для пустой строки функция должна вернуть 0"
return false
end
-- Тест 3: не строка
local ok3, result3 = pcall(_G.ExtractItemIDFromLink, 123)
if not ok3 or result3 ~= 0 then
_G.checkError = "Для нестрокового аргумента функция должна вернуть 0"
return false
end
-- Тест 4: строка без ссылки предмета
local ok4, result4 = pcall(_G.ExtractItemIDFromLink, "просто текст")
if not ok4 or result4 ~= 0 then
_G.checkError = "Для строки без ссылки предмета функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][303] = {
type = "commenttest",
title = "Тест: функция ExtractItemNameFromLink",
helpModules = {299, 33, 45, 65},
preloadVars = {
{var = "ExtractItemNameFromLink", desc = "ExtractItemNameFromLink очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 275-4: функция ExtractItemNameFromLink</h>
<t>Создай глобальную функцию <k>ExtractItemNameFromLink(link)</k>.</t>
<t>Если <k>link</k> не является строкой или является пустой строкой, функция должна вернуть строку:</t>
<s>"нет"</s>
<t>Иначе функция должна извлечь название предмета из квадратных скобок через:</t>
<code>
link:match("%[(.+)%]")
</code>
<t>Если результат не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"нет"</s>
<t>Иначе функция должна вернуть название предмета.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию ExtractItemNameFromLink(link)
]=],
requireKeywords = {
"ExtractItemNameFromLink",
"function",
"string.match",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.ExtractItemNameFromLink) ~= "function" then
_G.checkError = "ExtractItemNameFromLink не является глобальной функцией"
return false
end
-- Тест 1: реальная ссылка камня возвращения
local realName, realLink = GetItemInfo(6948)
if realLink then
local ok1, result1 = pcall(_G.ExtractItemNameFromLink, realLink)
if not ok1 then
_G.checkError = "Ошибка вызова ExtractItemNameFromLink с реальной ссылкой: " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для ссылки камня возвращения функция должна вернуть строку"
return false
end
end
-- Тест 2: пустая строка
local ok2, result2 = pcall(_G.ExtractItemNameFromLink, "")
if not ok2 or result2 ~= "нет" then
_G.checkError = "Для пустой строки функция должна вернуть 'нет'"
return false
end
-- Тест 3: не строка
local ok3, result3 = pcall(_G.ExtractItemNameFromLink, 123)
if not ok3 or result3 ~= "нет" then
_G.checkError = "Для нестрокового аргумента функция должна вернуть 'нет'"
return false
end
-- Тест 4: строка без квадратных скобок
local ok4, result4 = pcall(_G.ExtractItemNameFromLink, "просто текст")
if not ok4 or result4 ~= "нет" then
_G.checkError = "Для строки без квадратных скобок функция должна вернуть 'нет'"
return false
end
return true
end,
}

ns_llua['lua'][304] = {
type = "commenttest",
title = "Тест: функция IsItemLink",
helpModules = {299, 33, 45, 65},
preloadVars = {
{var = "IsItemLink", desc = "IsItemLink очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 275-5: функция IsItemLink</h>
<t>Создай глобальную функцию <k>IsItemLink(link)</k>.</t>
<t>Если <k>link</k> не является строкой или является пустой строкой, функция должна вернуть <k>false</k>.</t>
<t>Иначе функция должна проверить, является ли строка ссылкой на предмет.</t>
<t>Строка считается ссылкой на предмет, если она содержит подстроку:</t>
<s>"|Hitem:"</s>
<t>Используй <k>string.find</k> с четвёртым аргументом <k>true</k> для поиска без паттернов.</t>
<t>Функция должна вернуть <k>true</k> если строка является ссылкой на предмет, иначе <k>false</k>.</t>
<t>Результат должен быть именно boolean. Используй приведение через <k>and true or false</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию IsItemLink(link)
]=],
requireKeywords = {
"IsItemLink",
"function",
"string.find",
"and",
"or",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.IsItemLink) ~= "function" then
_G.checkError = "IsItemLink не является глобальной функцией"
return false
end
-- Тест 1: реальная ссылка камня возвращения
local _, realLink = GetItemInfo(6948)
if realLink then
local ok1, result1 = pcall(_G.IsItemLink, realLink)
if not ok1 then
_G.checkError = "Ошибка вызова IsItemLink с реальной ссылкой: " .. tostring(result1)
return false
end
if result1 ~= true then
_G.checkError = "Для реальной ссылки предмета функция должна вернуть true"
return false
end
end
-- Тест 2: пустая строка
local ok2, result2 = pcall(_G.IsItemLink, "")
if not ok2 or result2 ~= false then
_G.checkError = "Для пустой строки функция должна вернуть false"
return false
end
-- Тест 3: не строка
local ok3, result3 = pcall(_G.IsItemLink, 123)
if not ok3 or result3 ~= false then
_G.checkError = "Для нестрокового аргумента функция должна вернуть false"
return false
end
-- Тест 4: обычный текст
local ok4, result4 = pcall(_G.IsItemLink, "просто текст")
if not ok4 or result4 ~= false then
_G.checkError = "Для обычного текста функция должна вернуть false"
return false
end
-- Тест 5: ссылка на заклинание (не предмет)
local ok5, result5 = pcall(_G.IsItemLink, "|cff71d5ff|Hspell:6603|h[Тест]|h|r")
if not ok5 or result5 ~= false then
_G.checkError = "Для ссылки на заклинание функция должна вернуть false"
return false
end
return true
end,
}

ns_llua['lua'][305] = {
type = "info",
title = "Статы персонажа и UnitStat",
helpModules = {65, 45, 10},
content = [=[
<h>Статы персонажа и UnitStat</h>
<t>Функция <k>UnitStat</k> возвращает характеристики персонажа: силу, ловкость, выносливость, интеллект и дух.</t>
<h>Индексы статов</h>
<c>1</c> — Сила (Strength).
<c>2</c> — Ловкость (Agility).
<c>3</c> — Выносливость (Stamina).
<c>4</c> — Интеллект (Intellect).
<c>5</c> — Дух (Spirit).
<h>UnitStat</h>
<code>
/run local base, effective, modifier = UnitStat("player", 1); print(base, effective, modifier)
</code>
<t>Функция возвращает три значения:</t>
<c>base</c> — базовое значение стата без баффов и дебаффов.
<c>effective</c> — эффективное значение с учётом всех модификаторов.
<c>modifier</c> — разница между эффективным и базовым значениями.
<h>Безопасный шаблон</h>
<code>
/run local base, effective = UnitStat("player", 1); print(base or 0, effective or 0)
</code>
<h>Атака и броня</h>
<code>
/run print(UnitAttackPower("player"))
/run print(UnitArmor("player"))
/run print(UnitDamage("player"))
/run print(UnitAttackSpeed("player"))
</code>
<t>Основные функции:</t>
<c>UnitAttackPower</c> — сила атаки.
<c>UnitRangedAttackPower</c> — сила дальней атаки.
<c>UnitDamage</c> — минимальный и максимальный урон.
<c>UnitAttackSpeed</c> — скорость атаки.
<c>UnitArmor</c> — броня.
<h>Сопротивления</h>
<code>
/run print(UnitResistance("player", 0))
</code>
<t>Индексы сопротивлений:</t>
<c>0</c> — физическое.
<c>1</c> — святое.
<c>2</c> — огонь.
<c>3</c> — природа.
<c>4</c> — лёд.
<c>5</c> — тьма.
<c>6</c> — тайная магия.
<h>Перебор всех статов</h>
<code>
/run for i = 1, 5 do local base, effective = UnitStat("player", i); print("Stat " .. i .. ": " .. (effective or 0)) end
</code>
<h>Таблица статов</h>
<code>
/run local stats = {}; for i = 1, 5 do local _, effective = UnitStat("player", i); stats[i] = effective or 0 end; print("Сила: " .. stats[1], "Ловкость: " .. stats[2])
</code>
<w>Важно:</w> значения статов зависят от баффов, экипировки и талантов. Эффективное значение может меняться в реальном времени.
]=],
}

ns_llua['lua'][306] = {
type = "vartest",
title = "Тест: базовые статы",
helpModules = {305, 65},
tasks = {
{
var = "playerStrength",
desc = 'Создай глобальную переменную playerStrength = select(2, UnitStat("player", 1)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerAgility",
desc = 'Создай глобальную переменную playerAgility = select(2, UnitStat("player", 2)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerStamina",
desc = 'Создай глобальную переменную playerStamina = select(2, UnitStat("player", 3)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][307] = {
type = "vartest",
title = "Тест: интеллект, дух, атака и броня",
helpModules = {305, 65},
tasks = {
{
var = "playerIntellect",
desc = 'Создай глобальную переменную playerIntellect = select(2, UnitStat("player", 4)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerSpirit",
desc = 'Создай глобальную переменную playerSpirit = select(2, UnitStat("player", 5)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerAttackPower",
desc = 'Создай глобальную переменную playerAttackPower = UnitAttackPower("player") or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerArmor",
desc = 'Создай глобальную переменную playerArmor = UnitArmor("player") or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][308] = {
type = "commenttest",
title = "Тест: функция GetStatSafe",
helpModules = {305, 45, 65},
preloadVars = {
{var = "GetStatSafe", desc = "GetStatSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 281-3: функция GetStatSafe</h>
<t>Создай глобальную функцию <k>GetStatSafe(unit, statIndex)</k>.</t>
<t>Если <k>unit</k> не является строкой, функция должна вернуть <n>0</n>.</t>
<t>Если <k>statIndex</k> не является числом или меньше 1 или больше 5, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить эффективное значение стата через:</t>
<code>
select(2, UnitStat(unit, statIndex))
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть эффективное значение стата.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetStatSafe(unit, statIndex)
]=],
requireKeywords = {
"GetStatSafe",
"function",
"UnitStat",
"select",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetStatSafe) ~= "function" then
_G.checkError = "GetStatSafe не является глобальной функцией"
return false
end
-- Тест 1: корректный вызов для всех статов
for i = 1, 5 do
local ok, result = pcall(_G.GetStatSafe, "player", i)
if not ok then
_G.checkError = "Ошибка вызова GetStatSafe('player', " .. i .. "): " .. tostring(result)
return false
end
if type(result) ~= "number" or result < 0 then
_G.checkError = "Для statIndex = " .. i .. " функция должна вернуть число больше или равное нулю"
return false
end
end
-- Тест 2: некорректный unit
local ok2, result2 = pcall(_G.GetStatSafe, 123, 1)
if not ok2 or result2 ~= 0 then
_G.checkError = "Для нестрокового unit функция должна вернуть 0"
return false
end
-- Тест 3: некорректный statIndex
local ok3, result3 = pcall(_G.GetStatSafe, "player", 0)
if not ok3 or result3 ~= 0 then
_G.checkError = "Для statIndex = 0 функция должна вернуть 0"
return false
end
local ok4, result4 = pcall(_G.GetStatSafe, "player", 6)
if not ok4 or result4 ~= 0 then
_G.checkError = "Для statIndex = 6 функция должна вернуть 0"
return false
end
local ok5, result5 = pcall(_G.GetStatSafe, "player", "bad")
if not ok5 or result5 ~= 0 then
_G.checkError = "Для нечислового statIndex функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][309] = {
type = "commenttest",
title = "Тест: функция GetStatName",
helpModules = {305, 45, 17, 19},
preloadVars = {
{var = "GetStatName", desc = "GetStatName очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 281-4: функция GetStatName</h>
<t>Создай глобальную функцию <k>GetStatName(statIndex)</k>.</t>
<t>Функция должна вернуть название стата по индексу:</t>
<c>1</c> — <s>"Сила"</s>
<c>2</c> — <s>"Ловкость"</s>
<c>3</c> — <s>"Выносливость"</s>
<c>4</c> — <s>"Интеллект"</s>
<c>5</c> — <s>"Дух"</s>
<t>Если <k>statIndex</k> не является числом или меньше 1 или больше 5, функция должна вернуть:</t>
<s>"Неизвестно"</s>
<t>Используй:</t>
<c>type</c>
<c>if / elseif / else</c>
<c>return</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetStatName(statIndex)
]=],
requireKeywords = {
"GetStatName",
"function",
"type",
"if",
"elseif",
"else",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetStatName) ~= "function" then
_G.checkError = "GetStatName не является глобальной функцией"
return false
end
local tests = {
{input = 1, expected = "Сила"},
{input = 2, expected = "Ловкость"},
{input = 3, expected = "Выносливость"},
{input = 4, expected = "Интеллект"},
{input = 5, expected = "Дух"},
{input = 0, expected = "Неизвестно"},
{input = 6, expected = "Неизвестно"},
{input = "bad", expected = "Неизвестно"},
}
for i, test in ipairs(tests) do
local ok, result = pcall(_G.GetStatName, test.input)
if not ok or result ~= test.expected then
_G.checkError = "Тест " .. i .. " функции GetStatName не пройден"
return false
end
end
return true
end,
}

ns_llua['lua'][310] = {
type = "commenttest",
title = "Тест: функция GetStatReport",
helpModules = {305, 45, 31, 65, 7},
preloadVars = {
{var = "GetStatReport", desc = "GetStatReport очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 281-5: функция GetStatReport</h>
<t>Создай глобальную функцию <k>GetStatReport(unit)</k>.</t>
<t>Если <k>unit</k> не является строкой, функция должна вернуть строку:</t>
<s>"Нет юнита"</s>
<t>Иначе функция должна собрать строку с эффективными значениями всех пяти статов.</t>
<t>Формат строки:</t>
<s>"Сила: X, Ловкость: X, Выносливость: X, Интеллект: X, Дух: X"</s>
<t>Где X — эффективное значение соответствующего стата.</t>
<t>Используй:</t>
<c>UnitStat(unit, index)</c>
<c>select(2, ...)</c>
<c>or 0</c>
<c>string.format</c>
<c>конкатенацию</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetStatReport(unit)
]=],
requireKeywords = {
"GetStatReport",
"function",
"UnitStat",
"select",
"string.format",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetStatReport) ~= "function" then
_G.checkError = "GetStatReport не является глобальной функцией"
return false
end
-- Тест 1: корректный вызов
local ok1, result1 = pcall(_G.GetStatReport, "player")
if not ok1 then
_G.checkError = "Ошибка вызова GetStatReport('player'): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для player функция должна вернуть строку"
return false
end
if not result1:find("Сила: ", 1, true) then
_G.checkError = "Строка должна содержать 'Сила: '"
return false
end
if not result1:find("Ловкость: ", 1, true) then
_G.checkError = "Строка должна содержать 'Ловкость: '"
return false
end
if not result1:find("Выносливость: ", 1, true) then
_G.checkError = "Строка должна содержать 'Выносливость: '"
return false
end
if not result1:find("Интеллект: ", 1, true) then
_G.checkError = "Строка должна содержать 'Интеллект: '"
return false
end
if not result1:find("Дух: ", 1, true) then
_G.checkError = "Строка должна содержать 'Дух: '"
return false
end
-- Тест 2: некорректный unit
local ok2, result2 = pcall(_G.GetStatReport, 123)
if not ok2 or result2 ~= "Нет юнита" then
_G.checkError = "Для нестрокового unit функция должна вернуть 'Нет юнита'"
return false
end
return true
end,
}

ns_llua['lua'][311] = {
type = "info",
title = "Атака, урон, броня и сопротивления",
helpModules = {305, 65, 45},
content = [=[
<h>Атака, урон, броня и сопротивления</h>
<t>WoW API предоставляет функции для получения боевых характеристик персонажа и других юнитов.</t>
<h>UnitAttackPower</h>
<code>
/run print(UnitAttackPower("player"))
</code>
<t>Возвращает силу атаки юнита. Чем выше значение, тем больше физический урон.</t>
<h>UnitRangedAttackPower</h>
<code>
/run print(UnitRangedAttackPower("player"))
</code>
<t>Возвращает силу дальней атаки. Актуально для классов с луками и арбалетами.</t>
<h>UnitDamage</h>
<code>
/run local minDmg, maxDmg = UnitDamage("player"); print(minDmg, maxDmg)
</code>
<t>Возвращает минимальный и максимальный урон юнита.</t>
<t>Если нужен средний урон, можно посчитать:</t>
<code>
/run local minDmg, maxDmg = UnitDamage("player"); if minDmg and maxDmg then print(string.format("Средний урон: %.1f", (minDmg + maxDmg) / 2)) end
</code>
<h>UnitAttackSpeed</h>
<code>
/run print(UnitAttackSpeed("player"))
</code>
<t>Возвращает скорость атаки в секундах. Меньшее значение — быстрее атака.</t>
<h>UnitArmor</h>
<code>
/run print(UnitArmor("player"))
</code>
<t>Возвращает значение брони юнита. Броня уменьшает получаемый физический урон.</t>
<h>UnitResistance</h>
<t>Возвращает сопротивление юнита к школе магии.</t>
<code>
/run print(UnitResistance("player", 0))
</code>
<t>Школы магии:</t>
<c>0</c> — физическое.
<c>1</c> — святое (Holy).
<c>2</c> — огонь (Fire).
<c>3</c> — природа (Nature).
<c>4</c> — лёд (Frost).
<c>5</c> — тьма (Shadow).
<c>6</c> — тайная магия (Arcane).
<h>Перебор всех сопротивлений</h>
<code>
/run for school = 0, 6 do print("Школа " .. school .. ": " .. (UnitResistance("player", school) or 0)) end
</code>
<h>Безопасный шаблон</h>
<code>
/run local ap = UnitAttackPower("player") or 0; local armor = UnitArmor("player") or 0; print(string.format("АП: %d, Броня: %d", ap, armor))
</code>
<w>Важно:</w> все эти функции могут вернуть <k>nil</k>, если юнит не существует или данные недоступны. Всегда используй <k>or 0</k> для безопасности.
<h>Пример боевого отчёта</h>
<code>
/run local ap = UnitAttackPower("player") or 0; local minD, maxD = UnitDamage("player"); local armor = UnitArmor("player") or 0; local speed = UnitAttackSpeed("player") or 0; print(string.format("АП: %d | Урон: %.0f-%.0f | Броня: %d | Скорость: %.1f", ap, minD or 0, maxD or 0, armor, speed))
</code>
]=],
}

ns_llua['lua'][312] = {
type = "vartest",
title = "Тест: сила атаки и броня",
helpModules = {311, 65},
tasks = {
{
var = "playerAttackPower",
desc = 'Создай глобальную переменную playerAttackPower = UnitAttackPower("player") or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerRangedAttackPower",
desc = 'Создай глобальную переменную playerRangedAttackPower = UnitRangedAttackPower("player") or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerArmor",
desc = 'Создай глобальную переменную playerArmor = UnitArmor("player") or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][313] = {
type = "vartest",
title = "Тест: скорость атаки и урон",
helpModules = {311, 65},
tasks = {
{
var = "playerAttackSpeed",
desc = 'Создай глобальную переменную playerAttackSpeed = UnitAttackSpeed("player") or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerMinDamage",
desc = 'Создай глобальную переменную playerMinDamage = UnitDamage("player") or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "playerMaxDamage",
desc = 'Создай глобальную переменную playerMaxDamage = select(2, UnitDamage("player")) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][314] = {
type = "commenttest",
title = "Тест: функция GetAttackPowerSafe",
helpModules = {311, 45, 65},
preloadVars = {
{var = "GetAttackPowerSafe", desc = "GetAttackPowerSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 287-3: функция GetAttackPowerSafe</h>
<t>Создай глобальную функцию <k>GetAttackPowerSafe(unit)</k>.</t>
<t>Если <k>unit</k> не является строкой, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить силу атаки через:</t>
<code>
UnitAttackPower(unit)
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть силу атаки.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetAttackPowerSafe(unit)
]=],
requireKeywords = {
"GetAttackPowerSafe",
"function",
"UnitAttackPower",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetAttackPowerSafe) ~= "function" then
_G.checkError = "GetAttackPowerSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetAttackPowerSafe, "player")
if not ok1 then
_G.checkError = "Ошибка вызова GetAttackPowerSafe('player'): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < 0 then
_G.checkError = "Для player функция должна вернуть число больше или равное нулю"
return false
end
local ok2, result2 = pcall(_G.GetAttackPowerSafe, "ns_invalid_unit")
if not ok2 or result2 ~= 0 then
_G.checkError = "Для несуществующего юнита функция должна вернуть 0"
return false
end
local ok3, result3 = pcall(_G.GetAttackPowerSafe, 123)
if not ok3 or result3 ~= 0 then
_G.checkError = "Для нестрокового unit функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][315] = {
type = "commenttest",
title = "Тест: функция GetDamageRange",
helpModules = {311, 45, 65},
preloadVars = {
{var = "GetDamageRange", desc = "GetDamageRange очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 287-4: функция GetDamageRange</h>
<t>Создай глобальную функцию <k>GetDamageRange(unit)</k>.</t>
<t>Если <k>unit</k> не является строкой, функция должна вернуть два значения: <n>0</n> и <n>0</n>.</t>
<t>Иначе функция должна получить минимальный и максимальный урон через:</t>
<code>
UnitDamage(unit)
</code>
<t>Если минимальный урон не является числом или меньше нуля, верни <n>0</n> для минимального.</t>
<t>Если максимальный урон не является числом или меньше нуля, верни <n>0</n> для максимального.</t>
<t>Иначе функция должна вернуть два числа: минимальный урон и максимальный урон.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetDamageRange(unit)
]=],
requireKeywords = {
"GetDamageRange",
"function",
"UnitDamage",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetDamageRange) ~= "function" then
_G.checkError = "GetDamageRange не является глобальной функцией"
return false
end
local ok1, minD, maxD = pcall(_G.GetDamageRange, "player")
if not ok1 then
_G.checkError = "Ошибка вызова GetDamageRange('player'): " .. tostring(minD)
return false
end
if type(minD) ~= "number" or type(maxD) ~= "number" then
_G.checkError = "Для player функция должна вернуть два числа"
return false
end
if minD < 0 or maxD < 0 then
_G.checkError = "Значения урона не должны быть отрицательными"
return false
end
local ok2, invalidMin, invalidMax = pcall(_G.GetDamageRange, "ns_invalid_unit")
if not ok2 then
_G.checkError = "Ошибка вызова GetDamageRange('ns_invalid_unit'): " .. tostring(invalidMin)
return false
end
if invalidMin ~= 0 or invalidMax ~= 0 then
_G.checkError = "Для несуществующего юнита функция должна вернуть 0 и 0"
return false
end
local ok3, badMin, badMax = pcall(_G.GetDamageRange, 123)
if not ok3 or badMin ~= 0 or badMax ~= 0 then
_G.checkError = "Для нестрокового unit функция должна вернуть 0 и 0"
return false
end
return true
end,
}

ns_llua['lua'][316] = {
type = "commenttest",
title = "Тест: функция GetResistanceSafe",
helpModules = {311, 45, 65},
preloadVars = {
{var = "GetResistanceSafe", desc = "GetResistanceSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 287-5: функция GetResistanceSafe</h>
<t>Создай глобальную функцию <k>GetResistanceSafe(unit, school)</k>.</t>
<t>Если <k>unit</k> не является строкой, функция должна вернуть <n>0</n>.</t>
<t>Если <k>school</k> не является числом или меньше нуля или больше 6, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна получить сопротивление через:</t>
<code>
UnitResistance(unit, school)
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть значение сопротивления.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetResistanceSafe(unit, school)
]=],
requireKeywords = {
"GetResistanceSafe",
"function",
"UnitResistance",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetResistanceSafe) ~= "function" then
_G.checkError = "GetResistanceSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetResistanceSafe, "player", 0)
if not ok1 then
_G.checkError = "Ошибка вызова GetResistanceSafe('player', 0): " .. tostring(result1)
return false
end
if type(result1) ~= "number" or result1 < 0 then
_G.checkError = "Для player и школы 0 функция должна вернуть число больше или равное нулю"
return false
end
local ok2, result2 = pcall(_G.GetResistanceSafe, "ns_invalid_unit", 0)
if not ok2 or result2 ~= 0 then
_G.checkError = "Для несуществующего юнита функция должна вернуть 0"
return false
end
local ok3, result3 = pcall(_G.GetResistanceSafe, "player", -1)
if not ok3 or result3 ~= 0 then
_G.checkError = "Для школы -1 функция должна вернуть 0"
return false
end
local ok4, result4 = pcall(_G.GetResistanceSafe, "player", 7)
if not ok4 or result4 ~= 0 then
_G.checkError = "Для школы 7 функция должна вернуть 0"
return false
end
local ok5, result5 = pcall(_G.GetResistanceSafe, 123, 0)
if not ok5 or result5 ~= 0 then
_G.checkError = "Для нестрокового unit функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][317] = {
type = "info",
title = "Профессии и торговля",
helpModules = {65, 45, 31},
content = [=[
<h>Профессии и торговля</h>
<t>WoW API позволяет получать информацию о профессиях игрока и о товарах торговцев.</t>
<w>Важно:</w> данные о навыках профессии доступны только когда окно профессии открыто. Данные о торговце доступны только когда окно торговца открыто. Если окно не открыто, функции могут вернуть <k>nil</k>.
<h>GetNumTradeSkills</h>
<code>
/run print(GetNumTradeSkills())
</code>
<t>Возвращает количество рецептов в текущей профессии. Если окно профессии не открыто, может вернуть <k>nil</k>.</t>
<h>GetTradeSkillLine</h>
<code>
/run local name, rank, maxRank = GetTradeSkillLine(); print(name or "нет", rank or 0, maxRank or 0)
</code>
<t>Возвращает три значения:</t>
<c>name</c> — название профессии.
<c>rank</c> — текущий уровень навыка.
<c>maxRank</c> — максимальный уровень навыка.
<h>GetTradeSkillInfo</h>
<code>
/run local name, skillType, available = GetTradeSkillInfo(1); print(name or "нет", skillType or "нет")
</code>
<t>Возвращает информацию о рецепте:</t>
<c>name</c> — название рецепта.
<c>skillType</c> — тип: <s>"header"</s> (заголовок категории) или <s>"spell"</s> (рецепт).
<c>available</c> — доступно ли создание.
<h>Перебор рецептов</h>
<code>
/run local count = GetNumTradeSkills() or 0; for i = 1, count do local name, skillType = GetTradeSkillInfo(i); if name and skillType == "spell" then print(name) end end
</code>
<t>Здесь мы пропускаем заголовки категорий и выводим только рецепты.</t>
<h>GetMerchantNumItems</h>
<code>
/run print(GetMerchantNumItems())
</code>
<t>Возвращает количество предметов у торговца. Если окно торговца не открыто, может вернуть <k>nil</k> или <n>0</n>.</t>
<h>GetMerchantItemInfo</h>
<code>
/run local name, texture, price, quantity = GetMerchantItemInfo(1); print(name or "нет", price or 0, quantity or 0)
</code>
<t>Возвращает информацию о предмете торговца:</t>
<c>name</c> — название предмета.
<c>texture</c> — иконка предмета.
<c>price</c> — цена в меди.
<c>quantity</c> — количество предметов в стопке.
<c>numAvailable</c> — сколько штук доступно.
<c>isUsable</c> — можно ли использовать.
<h>Перебор товаров торговца</h>
<code>
/run local count = GetMerchantNumItems() or 0; for i = 1, count do local name, _, price = GetMerchantItemInfo(i); if name then print(i, name, price or 0) end end
</code>
<h>Цена в золоте</h>
<t>Цена возвращается в меди. Чтобы перевести в золото, серебро и медь:</t>
<code>
/run local _, _, price = GetMerchantItemInfo(1); price = price or 0; local gold = math.floor(price / 10000); local silver = math.floor((price % 10000) / 100); local copper = price % 100; print(string.format("%dз %dс %dм", gold, silver, copper))
</code>
<h>Безопасный шаблон</h>
<code>
/run local count = GetNumTradeSkills() or 0; local name = GetTradeSkillLine() or "нет"; print(string.format("Профессия: %s, рецептов: %d", name, count))
</code>
<w>Примечание:</w> если вы хотите получить данные о профессии или торговце в аддоне, вам нужно дождаться, пока игрок откроет соответствующее окно, и использовать события для отслеживания этого момента.
]=],
}

ns_llua['lua'][318] = {
type = "vartest",
title = "Тест: профессия игрока",
helpModules = {317, 65},
tasks = {
{
var = "tradeSkillCount",
desc = 'Создай глобальную переменную tradeSkillCount = GetNumTradeSkills() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "tradeSkillName",
desc = 'Создай глобальную переменную tradeSkillName = GetTradeSkillLine() or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "tradeSkillRank",
desc = 'Создай глобальную переменную tradeSkillRank = select(2, GetTradeSkillLine()) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][319] = {
type = "vartest",
title = "Тест: торговец и предметы",
helpModules = {317, 65},
tasks = {
{
var = "merchantItemCount",
desc = 'Создай глобальную переменную merchantItemCount = GetMerchantNumItems() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "merchantFirstItemName",
desc = 'Создай глобальную переменную merchantFirstItemName = GetMerchantItemInfo(1) or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "merchantFirstItemPrice",
desc = 'Создай глобальную переменную merchantFirstItemPrice = select(3, GetMerchantItemInfo(1)) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][320] = {
type = "commenttest",
title = "Тест: функция GetTradeSkillCountSafe",
helpModules = {317, 45, 65},
preloadVars = {
{var = "GetTradeSkillCountSafe", desc = "GetTradeSkillCountSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 293-3: функция GetTradeSkillCountSafe</h>
<t>Создай глобальную функцию <k>GetTradeSkillCountSafe()</k>.</t>
<t>Функция должна вернуть количество рецептов в текущей профессии через:</t>
<code>
GetNumTradeSkills()
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть количество рецептов.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetTradeSkillCountSafe()
]=],
requireKeywords = {
"GetTradeSkillCountSafe",
"function",
"GetNumTradeSkills",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetTradeSkillCountSafe) ~= "function" then
_G.checkError = "GetTradeSkillCountSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetTradeSkillCountSafe)
if not ok then
_G.checkError = "Ошибка вызова GetTradeSkillCountSafe: " .. tostring(result)
return false
end
if type(result) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if result < 0 then
_G.checkError = "Количество рецептов не может быть отрицательным"
return false
end
return true
end,
}

ns_llua['lua'][321] = {
type = "commenttest",
title = "Тест: функция GetTradeSkillNameSafe",
helpModules = {317, 45, 65},
preloadVars = {
{var = "GetTradeSkillNameSafe", desc = "GetTradeSkillNameSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 293-4: функция GetTradeSkillNameSafe</h>
<t>Создай глобальную функцию <k>GetTradeSkillNameSafe(index)</k>.</t>
<t>Если <k>index</k> не является числом или меньше либо равно нуля, функция должна вернуть строку:</t>
<s>"нет"</s>
<t>Иначе функция должна получить имя рецепта через:</t>
<code>
GetTradeSkillInfo(index)
</code>
<t>Если результат не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"нет"</s>
<t>Иначе функция должна вернуть имя рецепта.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetTradeSkillNameSafe(index)
]=],
requireKeywords = {
"GetTradeSkillNameSafe",
"function",
"GetTradeSkillInfo",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetTradeSkillNameSafe) ~= "function" then
_G.checkError = "GetTradeSkillNameSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetTradeSkillNameSafe, 1)
if not ok1 then
_G.checkError = "Ошибка вызова GetTradeSkillNameSafe(1): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для index = 1 функция должна вернуть строку"
return false
end
local ok2, result2 = pcall(_G.GetTradeSkillNameSafe, 0)
if not ok2 or result2 ~= "нет" then
_G.checkError = "Для index = 0 функция должна вернуть 'нет'"
return false
end
local ok3, result3 = pcall(_G.GetTradeSkillNameSafe, "bad")
if not ok3 or result3 ~= "нет" then
_G.checkError = "Для нечислового index функция должна вернуть 'нет'"
return false
end
local ok4, result4 = pcall(_G.GetTradeSkillNameSafe, 999999)
if not ok4 then
_G.checkError = "Ошибка вызова GetTradeSkillNameSafe(999999): " .. tostring(result4)
return false
end
if result4 ~= "нет" then
_G.checkError = "Для несуществующего index функция должна вернуть 'нет'"
return false
end
return true
end,
}

ns_llua['lua'][322] = {
type = "commenttest",
title = "Тест: функция GetMerchantItemCountSafe",
helpModules = {317, 45, 65},
preloadVars = {
{var = "GetMerchantItemCountSafe", desc = "GetMerchantItemCountSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 293-5: функция GetMerchantItemCountSafe</h>
<t>Создай глобальную функцию <k>GetMerchantItemCountSafe()</k>.</t>
<t>Функция должна вернуть количество предметов у торговца через:</t>
<code>
GetMerchantNumItems()
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть количество предметов.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetMerchantItemCountSafe()
]=],
requireKeywords = {
"GetMerchantItemCountSafe",
"function",
"GetMerchantNumItems",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetMerchantItemCountSafe) ~= "function" then
_G.checkError = "GetMerchantItemCountSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetMerchantItemCountSafe)
if not ok then
_G.checkError = "Ошибка вызова GetMerchantItemCountSafe: " .. tostring(result)
return false
end
if type(result) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if result < 0 then
_G.checkError = "Количество предметов торговца не может быть отрицательным"
return false
end
return true
end,
}

ns_llua['lua'][323] = {
type = "info",
title = "Питомцы и тотемы",
helpModules = {77, 83, 65},
content = [=[
<h>Питомцы и тотемы</h>
<t>В WoW у некоторых классов есть питомцы и тотемы. WoW API позволяет получать информацию о них.</t>
<h>Питомцы</h>
<t>Питомец доступен через UnitID <s>"pet"</s>.</t>
<code>
/run print(UnitExists("pet"))
/run print(UnitName("pet"))
/run print(UnitLevel("pet"))
</code>
<h>Проверка наличия питомца</h>
<t>Функция <k>UnitExists("pet")</k> проверяет, существует ли питомец в данный момент.</t>
<code>
/run if UnitExists("pet") then print("Питомец есть") else print("Питомца нет") end
</code>
<h>HasPetUI</h>
<t>Функция <k>HasPetUI()</k> проверяет, есть ли у игрока интерфейс питомца. Это зависит от класса.</t>
<code>
/run print(HasPetUI())
</code>
<t>Для охотника, чернокнижника и некоторых других классов вернёт истинное значение. Для воина, разбойника и т.д. вернёт <k>nil</k> или <k>false</k>.</t>
<h>Здоровье питомца</h>
<code>
/run local hp = UnitHealth("pet") or 0; local hpMax = UnitHealthMax("pet") or 0; print(hp, hpMax)
</code>
<h>Семейство питомца</h>
<code>
/run print(UnitCreatureFamily("pet") or "нет")
</code>
<t>Возвращает семейство существа, например "Волк", "Кошка", "Бес" и т.д.</t>
<h>Тотемы</h>
<t>Тотемы доступны через функцию <k>GetTotemInfo(slot)</k>.</t>
<t>Слоты тотемов:</t>
<c>1</c> — огонь.
<c>2</c> — земля.
<c>3</c> — вода.
<c>4</c> — воздух.
<h>GetTotemInfo</h>
<code>
/run local haveTotem, name = GetTotemInfo(1); print(haveTotem, name or "нет")
</code>
<t>Функция возвращает несколько значений:</t>
<c>haveTotem</c> — есть ли тотем в этом слоте.
<c>name</c> — название тотема.
<c>startTime</c> — время установки.
<c>duration</c> — длительность.
<c>icon</c> — иконка тотема.
<h>Оставшееся время тотема</h>
<code>
/run print(GetTotemTimeLeft(1) or 0)
</code>
<t>Функция <k>GetTotemTimeLeft(slot)</k> возвращает оставшееся время тотема в секундах.</t>
<h>Перебор всех тотемов</h>
<code>
/run for slot = 1, 4 do local have, name = GetTotemInfo(slot); if have then print("Слот " .. slot .. ": " .. (name or "нет")) end end
</code>
<h>Безопасный шаблон</h>
<code>
/run local have, name = GetTotemInfo(1); have = have or false; name = name or "нет"; print(have, name)
</code>
<w>Важно:</w> если класс игрока не может ставить тотемы, все значения <k>haveTotem</k> будут ложными.
]=],
}

ns_llua['lua'][324] = {
type = "vartest",
title = "Тест: питомец игрока",
helpModules = {323, 65},
tasks = {
{
var = "petExists",
desc = 'Создай глобальную переменную petExists = not not UnitExists("pet")',
check = function(value)
return type(value) == "boolean"
end,
},
{
var = "petName",
desc = 'Создай глобальную переменную petName = UnitName("pet") or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "petLevel",
desc = 'Создай глобальную переменную petLevel = UnitLevel("pet") or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][325] = {
type = "vartest",
title = "Тест: тотемы и HasPetUI",
helpModules = {323, 65},
tasks = {
{
var = "hasPetUI",
desc = 'Создай глобальную переменную hasPetUI = not not HasPetUI()',
check = function(value)
return type(value) == "boolean"
end,
},
{
var = "totem1Exists",
desc = 'Создай глобальную переменную totem1Exists = not not GetTotemInfo(1)',
check = function(value)
return type(value) == "boolean"
end,
},
{
var = "totem1Name",
desc = 'Создай глобальную переменную totem1Name = select(2, GetTotemInfo(1)) or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
},
}

ns_llua['lua'][326] = {
type = "commenttest",
title = "Тест: функция HasPetSafe",
helpModules = {323, 45, 65},
preloadVars = {
{var = "HasPetSafe", desc = "HasPetSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 299-3: функция HasPetSafe</h>
<t>Создай глобальную функцию <k>HasPetSafe()</k>.</t>
<t>Функция должна вернуть <k>true</k>, если у игрока есть питомец.</t>
<t>Иначе функция должна вернуть <k>false</k>.</t>
<t>Используй:</t>
<c>UnitExists("pet")</c>
<t>Чтобы результат был именно boolean, используй конструкцию:</t>
<code>
return UnitExists("pet") and true or false
</code>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию HasPetSafe()
]=],
requireKeywords = {
"HasPetSafe",
"function",
"UnitExists",
"pet",
"and",
"or",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.HasPetSafe) ~= "function" then
_G.checkError = "HasPetSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.HasPetSafe)
if not ok then
_G.checkError = "Ошибка вызова HasPetSafe: " .. tostring(result)
return false
end
if type(result) ~= "boolean" then
_G.checkError = "Функция должна вернуть boolean"
return false
end
return true
end,
}

ns_llua['lua'][327] = {
type = "commenttest",
title = "Тест: функция GetPetHealthPercent",
helpModules = {323, 83, 65, 45},
preloadVars = {
{var = "GetPetHealthPercent", desc = "GetPetHealthPercent очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 299-4: функция GetPetHealthPercent</h>
<t>Создай глобальную функцию <k>GetPetHealthPercent()</k>.</t>
<t>Если питомца не существует, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть процент здоровья питомца от 0 до 100.</t>
<t>Используй:</t>
<c>UnitExists("pet")</c>
<c>UnitHealth("pet")</c>
<c>UnitHealthMax("pet")</c>
<c>or 0</c>
<c>math.floor</c>
<t>Если максимальное здоровье меньше или равно нуля, функция должна вернуть <n>0</n>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetPetHealthPercent()
]=],
requireKeywords = {
"GetPetHealthPercent",
"function",
"UnitExists",
"UnitHealth",
"UnitHealthMax",
"math.floor",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetPetHealthPercent) ~= "function" then
_G.checkError = "GetPetHealthPercent не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetPetHealthPercent)
if not ok then
_G.checkError = "Ошибка вызова GetPetHealthPercent: " .. tostring(result)
return false
end
if type(result) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if result < 0 or result > 100 then
_G.checkError = "Процент здоровья питомца должен быть от 0 до 100"
return false
end
return true
end,
}

ns_llua['lua'][328] = {
type = "commenttest",
title = "Тест: функция GetTotemInfoSafe",
helpModules = {323, 45, 65},
preloadVars = {
{var = "GetTotemInfoSafe", desc = "GetTotemInfoSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 299-5: функция GetTotemInfoSafe</h>
<t>Создай глобальную функцию <k>GetTotemInfoSafe(slot)</k>.</t>
<t>Если <k>slot</k> не является числом или меньше 1 или больше 4, функция должна вернуть два значения: <k>false</k> и строку <s>"нет"</s>.</t>
<t>Иначе функция должна получить данные тотема через:</t>
<code>
GetTotemInfo(slot)
</code>
<t>Если тотема нет, функция должна вернуть два значения: <k>false</k> и строку <s>"нет"</s>.</t>
<t>Если тотем есть, функция должна вернуть два значения: <k>true</k> и имя тотема.</t>
<t>Если имя тотема не является строкой или является пустой строкой, используй строку:</t>
<s>"нет"</s>
<t>Используй:</t>
<c>GetTotemInfo</c>
<c>select</c>
<c>type</c>
<c>return</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetTotemInfoSafe(slot)
]=],
requireKeywords = {
"GetTotemInfoSafe",
"function",
"GetTotemInfo",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetTotemInfoSafe) ~= "function" then
_G.checkError = "GetTotemInfoSafe не является глобальной функцией"
return false
end
-- Тест 1: корректный слот
local ok1, exists1, name1 = pcall(_G.GetTotemInfoSafe, 1)
if not ok1 then
_G.checkError = "Ошибка вызова GetTotemInfoSafe(1): " .. tostring(exists1)
return false
end
if type(exists1) ~= "boolean" then
_G.checkError = "Первое значение должно быть boolean"
return false
end
if type(name1) ~= "string" then
_G.checkError = "Второе значение должно быть строкой"
return false
end
-- Тест 2: некорректный слот
local ok2, exists2, name2 = pcall(_G.GetTotemInfoSafe, 0)
if not ok2 then
_G.checkError = "Ошибка вызова GetTotemInfoSafe(0): " .. tostring(exists2)
return false
end
if exists2 ~= false then
_G.checkError = "Для слота 0 первое значение должно быть false"
return false
end
if name2 ~= "нет" then
_G.checkError = "Для слота 0 второе значение должно быть 'нет'"
return false
end
-- Тест 3: некорректный слот
local ok3, exists3, name3 = pcall(_G.GetTotemInfoSafe, 5)
if not ok3 then
_G.checkError = "Ошибка вызова GetTotemInfoSafe(5): " .. tostring(exists3)
return false
end
if exists3 ~= false then
_G.checkError = "Для слота 5 первое значение должно быть false"
return false
end
if name3 ~= "нет" then
_G.checkError = "Для слота 5 второе значение должно быть 'нет'"
return false
end
-- Тест 4: нечисловой слот
local ok4, exists4, name4 = pcall(_G.GetTotemInfoSafe, "bad")
if not ok4 then
_G.checkError = "Ошибка вызова GetTotemInfoSafe('bad'): " .. tostring(exists4)
return false
end
if exists4 ~= false then
_G.checkError = "Для нечислового слота первое значение должно быть false"
return false
end
if name4 ~= "нет" then
_G.checkError = "Для нечислового слота второе значение должно быть 'нет'"
return false
end
return true
end,
}

ns_llua['lua'][329] = {
type = "info",
title = "Почта и банк",
helpModules = {65, 45, 31},
content = [=[
<h>Почта и банк</h>
<t>WoW API позволяет получать информацию о почте и банке персонажа.</t>
<w>Важно:</w> данные о почте и банке доступны только когда окно почты или банка открыто. Если окно не открыто, функции могут вернуть <k>nil</k>.
<h>CheckInbox</h>
<code>
/run CheckInbox()
</code>
<t>Эта функция обновляет данные почты. Её нужно вызвать перед получением информации о письмах.</t>
<h>GetInboxNumItems</h>
<code>
/run print(GetInboxNumItems())
</code>
<t>Возвращает количество писем в почтовом ящике.</t>
<h>GetInboxHeaderInfo</h>
<code>
/run local sender, subject = GetInboxHeaderInfo(1); print(sender or "нет", subject or "нет")
</code>
<t>Возвращает данные о письме:</t>
<c>sender</c> — имя отправителя.
<c>subject</c> — тема письма.
<c>money</c> — сумма денег в письме.
<c>COD</c> — сумма наложенного платежа.
<c>daysLeft</c> — сколько дней осталось до удаления письма.
<c>itemCount</c> — количество предметов в письме.
<c>wasRead</c> — прочитано ли письмо.
<c>wasReturned</c> — возвращено ли письмо.
<c>textCreated</c> — создан ли текст письма.
<c>canReply</c> — можно ли ответить.
<h>GetInboxText</h>
<code>
/run local text = GetInboxText(1); print(text or "нет текста")
</code>
<t>Возвращает текст письма.</t>
<h>Перебор писем</h>
<code>
/run local count = GetInboxNumItems() or 0; for i = 1, count do local sender, subject = GetInboxHeaderInfo(i); print(i, sender or "нет", subject or "нет") end
</code>
<h>GetNumBankSlots</h>
<code>
/run print(GetNumBankSlots())
</code>
<t>Возвращает количество слотов банка.</t>
<h>GetBankSlotCost</h>
<code>
/run print(GetBankSlotCost(1))
</code>
<t>Возвращает стоимость слота банка в меди.</t>
<h>Безопасный шаблон</h>
<code>
/run local count = GetInboxNumItems() or 0; print(string.format("Писем: %d", count))
</code>
<w>Примечание:</w> если вы хотите получить данные о почте или банке в аддоне, вам нужно дождаться, пока игрок откроет соответствующее окно, и использовать события для отслеживания этого момента.
]=],
}

ns_llua['lua'][330] = {
type = "vartest",
title = "Тест: почта игрока",
helpModules = {329, 65},
tasks = {
{
var = "inboxItemCount",
desc = 'Создай глобальную переменную inboxItemCount = GetInboxNumItems() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "firstMailSender",
desc = 'Создай глобальную переменную firstMailSender = GetInboxHeaderInfo(1) or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "firstMailSubject",
desc = 'Создай глобальную переменную firstMailSubject = select(2, GetInboxHeaderInfo(1)) or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
},
}

ns_llua['lua'][331] = {
type = "vartest",
title = "Тест: банк игрока",
helpModules = {329, 65},
tasks = {
{
var = "bankSlotCount",
desc = 'Создай глобальную переменную bankSlotCount = GetNumBankSlots() or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
{
var = "firstBankSlotCost",
desc = 'Создай глобальную переменную firstBankSlotCost = GetBankSlotCost(1) or 0',
check = function(value)
return type(value) == "number" and value >= 0
end,
},
},
}

ns_llua['lua'][332] = {
type = "commenttest",
title = "Тест: функция GetInboxItemCountSafe",
helpModules = {329, 45, 65},
preloadVars = {
{var = "GetInboxItemCountSafe", desc = "GetInboxItemCountSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 305-3: функция GetInboxItemCountSafe</h>
<t>Создай глобальную функцию <k>GetInboxItemCountSafe()</k>.</t>
<t>Функция должна вернуть количество писем в почтовом ящике через:</t>
<code>
GetInboxNumItems()
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть количество писем.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetInboxItemCountSafe()
]=],
requireKeywords = {
"GetInboxItemCountSafe",
"function",
"GetInboxNumItems",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetInboxItemCountSafe) ~= "function" then
_G.checkError = "GetInboxItemCountSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetInboxItemCountSafe)
if not ok then
_G.checkError = "Ошибка вызова GetInboxItemCountSafe: " .. tostring(result)
return false
end
if type(result) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if result < 0 then
_G.checkError = "Количество писем не может быть отрицательным"
return false
end
return true
end,
}

ns_llua['lua'][333] = {
type = "commenttest",
title = "Тест: функция GetMailSubjectSafe",
helpModules = {329, 45, 65},
preloadVars = {
{var = "GetMailSubjectSafe", desc = "GetMailSubjectSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 305-4: функция GetMailSubjectSafe</h>
<t>Создай глобальную функцию <k>GetMailSubjectSafe(index)</k>.</t>
<t>Если <k>index</k> не является числом или меньше либо равно нуля, функция должна вернуть строку:</t>
<s>"нет"</s>
<t>Иначе функция должна получить тему письма через:</t>
<code>
select(2, GetInboxHeaderInfo(index))
</code>
<t>Если результат не является строкой или является пустой строкой, функция должна вернуть:</t>
<s>"нет"</s>
<t>Иначе функция должна вернуть тему письма.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetMailSubjectSafe(index)
]=],
requireKeywords = {
"GetMailSubjectSafe",
"function",
"GetInboxHeaderInfo",
"select",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetMailSubjectSafe) ~= "function" then
_G.checkError = "GetMailSubjectSafe не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.GetMailSubjectSafe, 1)
if not ok1 then
_G.checkError = "Ошибка вызова GetMailSubjectSafe(1): " .. tostring(result1)
return false
end
if type(result1) ~= "string" or result1 == "" then
_G.checkError = "Для index = 1 функция должна вернуть строку"
return false
end
local ok2, result2 = pcall(_G.GetMailSubjectSafe, 0)
if not ok2 or result2 ~= "нет" then
_G.checkError = "Для index = 0 функция должна вернуть 'нет'"
return false
end
local ok3, result3 = pcall(_G.GetMailSubjectSafe, "bad")
if not ok3 or result3 ~= "нет" then
_G.checkError = "Для нечислового index функция должна вернуть 'нет'"
return false
end
return true
end,
}

ns_llua['lua'][334] = {
type = "commenttest",
title = "Тест: функция GetBankSlotCountSafe",
helpModules = {329, 45, 65},
preloadVars = {
{var = "GetBankSlotCountSafe", desc = "GetBankSlotCountSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 305-5: функция GetBankSlotCountSafe</h>
<t>Создай глобальную функцию <k>GetBankSlotCountSafe()</k>.</t>
<t>Функция должна вернуть количество слотов банка через:</t>
<code>
GetNumBankSlots()
</code>
<t>Если результат не является числом или меньше нуля, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна вернуть количество слотов банка.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetBankSlotCountSafe()
]=],
requireKeywords = {
"GetBankSlotCountSafe",
"function",
"GetNumBankSlots",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetBankSlotCountSafe) ~= "function" then
_G.checkError = "GetBankSlotCountSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.GetBankSlotCountSafe)
if not ok then
_G.checkError = "Ошибка вызова GetBankSlotCountSafe: " .. tostring(result)
return false
end
if type(result) ~= "number" then
_G.checkError = "Функция должна вернуть число"
return false
end
if result < 0 then
_G.checkError = "Количество слотов банка не может быть отрицательным"
return false
end
return true
end,
}

ns_llua['lua'][335] = {
type = "info",
title = "SavedVariables и сохранение данных",
helpModules = {44, 65, 45},
content = [=[
<h>SavedVariables и сохранение данных</h>
<t>В WoW 3.3.5 данные аддонов сохраняются между сессиями через механизм SavedVariables. Это позволяет аддону запоминать настройки, позиции, статистику и другие данные игрока.</t>
<h>Как это работает</h>
<t>В файле аддона с расширением <c>.toc</c> указываются имена глобальных переменных, которые нужно сохранять:</t>
<code>
## SavedVariables: MyAddonDB
## SavedVariablesPerCharacter: MyAddonCharDB
</code>
<t>Разница:</t>
<c>SavedVariables</c> — переменная общая для всех персонажей на аккаунте.
<c>SavedVariablesPerCharacter</c> — переменная уникальная для каждого персонажа.
<h>Когда данные сохраняются</h>
<t>WoW сохраняет данные при:</t>
<c>/reload</c> — перезагрузка интерфейса.
Выход из игры.
Смена персонажа.
<w>Важно:</w> если игрок убьёт процесс игры через диспетчер задач, данные могут не сохраниться.
<h>Глобальная переменная как хранилище</h>
<t>Обычно для сохранения используют одну глобальную таблицу:</t>
<code>
MyAddonDB = MyAddonDB or {}
</code>
<t>Конструкция <k>or {}</k> гарантирует, что при первом запуске (когда переменная ещё <k>nil</k>) будет создана пустая таблица.</t>
<h>Хранение данных в таблице</h>
<code>
MyAddonDB = MyAddonDB or {}
MyAddonDB.settings = MyAddonDB.settings or {}
MyAddonDB.settings.showMinimap = true
MyAddonDB.settings.fontSize = 12
MyAddonDB.lastLogin = time()
</code>
<h>Безопасная инициализация</h>
<t>При загрузке аддона нужно проверить, существуют ли данные, и создать значения по умолчанию:</t>
<code>
MyAddonDB = MyAddonDB or {}
MyAddonDB.settings = MyAddonDB.settings or {}
if MyAddonDB.settings.fontSize == nil then
    MyAddonDB.settings.fontSize = 12
end
</code>
<h>Чтение сохранённых данных</h>
<code>
MyAddonDB = MyAddonDB or {}
local fontSize = MyAddonDB.settings and MyAddonDB.settings.fontSize or 12
print("Размер шрифта: " .. fontSize)
</code>
<w>Важно:</w> если <k>MyAddonDB.settings</k> равно <k>nil</k>, то попытка прочитать <k>MyAddonDB.settings.fontSize</k> вызовет ошибку. Поэтому сначала проверяем наличие <k>settings</k>.
<h>Сохранение при выходе</h>
<t>Данные сохраняются автоматически при выходе. Но если нужно сохранить что-то в момент события, можно использовать:</t>
<code>
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function()
    MyAddonDB = MyAddonDB or {}
    MyAddonDB.lastLogout = time()
end)
</code>
<h>Функция time()</h>
<code>
/run print(time())
</code>
<t>Возвращает текущее время в секундах с 1 января 1970 года (Unix timestamp).</t>
]=],
}

ns_llua['lua'][336] = {
type = "vartest",
title = "Тест: структура для сохранения",
helpModules = {335, 44},
tasks = {
{
var = "nsCourseDB",
desc = 'Создай глобальную переменную nsCourseDB = {} (пустая таблица, имитация хранилища)',
check = function(value)
return type(value) == "table"
end,
},
{
var = "nsCourseDB_settings",
desc = 'Создай глобальную переменную nsCourseDB_settings: присвой nsCourseDB.settings = {} и затем сохрани ссылку в nsCourseDB_settings',
check = function(value)
return type(value) == "table"
end,
},
},
}

ns_llua['lua'][337] = {
type = "vartest",
title = "Тест: безопасная инициализация",
helpModules = {335, 44, 65},
tasks = {
{
var = "nsSafeDB",
desc = 'Создай глобальную переменную nsSafeDB: используй конструкцию nsSafeDB = nsSafeDB or {} для безопасной инициализации',
check = function(value)
return type(value) == "table"
end,
},
{
var = "nsSafeDB_defaultValue",
desc = 'Создай глобальную переменную nsSafeDB_defaultValue: если nsSafeDB.value равно nil, присвой 42, иначе оставь как есть. Сохрани результат в nsSafeDB_defaultValue',
check = function(value)
return type(value) == "number" and value == 42
end,
},
},
}

ns_llua['lua'][338] = {
type = "commenttest",
title = "Тест: функция SaveKeyValue",
helpModules = {335, 44, 45},
preloadVars = {
{var = "SaveKeyValue", desc = "SaveKeyValue очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
{var = "nsTestDB", desc = "nsTestDB очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 311-3: функция SaveKeyValue</h>
<t>Создай глобальную функцию <k>SaveKeyValue(db, key, value)</k>.</t>
<t>Если <k>db</k> не является таблицей, функция должна вернуть <k>false</k>.</t>
<t>Если <k>key</k> не является строкой или является пустой строкой, функция должна вернуть <k>false</k>.</t>
<t>Иначе функция должна сохранить значение в таблицу: <k>db[key] = value</k> и вернуть <k>true</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию SaveKeyValue(db, key, value)
]=],
requireKeywords = {
"SaveKeyValue",
"function",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.SaveKeyValue) ~= "function" then
_G.checkError = "SaveKeyValue не является глобальной функцией"
return false
end
_G.nsTestDB = {}
local ok1, result1 = pcall(_G.SaveKeyValue, _G.nsTestDB, "testKey", 123)
if not ok1 then
_G.checkError = "Ошибка вызова SaveKeyValue: " .. tostring(result1)
return false
end
if result1 ~= true then
_G.checkError = "Для корректных данных функция должна вернуть true"
return false
end
if _G.nsTestDB.testKey ~= 123 then
_G.checkError = "Значение не было сохранено в таблицу"
return false
end
local ok2, result2 = pcall(_G.SaveKeyValue, nil, "key", 1)
if not ok2 or result2 ~= false then
_G.checkError = "Для nil-таблицы функция должна вернуть false"
return false
end
local ok3, result3 = pcall(_G.SaveKeyValue, _G.nsTestDB, "", 1)
if not ok3 or result3 ~= false then
_G.checkError = "Для пустого ключа функция должна вернуть false"
return false
end
return true
end,
}

ns_llua['lua'][339] = {
type = "commenttest",
title = "Тест: функция LoadKeyValue",
helpModules = {335, 44, 45, 65},
preloadVars = {
{var = "LoadKeyValue", desc = "LoadKeyValue очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 311-4: функция LoadKeyValue</h>
<t>Создай глобальную функцию <k>LoadKeyValue(db, key, default)</k>.</t>
<t>Если <k>db</k> не является таблицей, функция должна вернуть <k>default</k>.</t>
<t>Если <k>key</k> не является строкой или является пустой строкой, функция должна вернуть <k>default</k>.</t>
<t>Если <k>db[key]</k> равно <k>nil</k>, функция должна вернуть <k>default</k>.</t>
<t>Иначе функция должна вернуть <k>db[key]</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию LoadKeyValue(db, key, default)
]=],
requireKeywords = {
"LoadKeyValue",
"function",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.LoadKeyValue) ~= "function" then
_G.checkError = "LoadKeyValue не является глобальной функцией"
return false
end
local testDB = { existingKey = "hello", numKey = 42 }
local ok1, result1 = pcall(_G.LoadKeyValue, testDB, "existingKey", "default")
if not ok1 then
_G.checkError = "Ошибка вызова LoadKeyValue: " .. tostring(result1)
return false
end
if result1 ~= "hello" then
_G.checkError = "Для существующего ключа функция должна вернуть значение из таблицы"
return false
end
local ok2, result2 = pcall(_G.LoadKeyValue, testDB, "missingKey", "default")
if not ok2 or result2 ~= "default" then
_G.checkError = "Для отсутствующего ключа функция должна вернуть default"
return false
end
local ok3, result3 = pcall(_G.LoadKeyValue, nil, "key", "default")
if not ok3 or result3 ~= "default" then
_G.checkError = "Для nil-таблицы функция должна вернуть default"
return false
end
local ok4, result4 = pcall(_G.LoadKeyValue, testDB, "", "default")
if not ok4 or result4 ~= "default" then
_G.checkError = "Для пустого ключа функция должна вернуть default"
return false
end
return true
end,
}

ns_llua['lua'][340] = {
type = "commenttest",
title = "Тест: функция InitSavedData",
helpModules = {335, 44, 45, 17},
preloadVars = {
{var = "InitSavedData", desc = "InitSavedData очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 311-5: функция InitSavedData</h>
<t>Создай глобальную функцию <k>InitSavedData(db)</k>.</t>
<t>Если <k>db</k> не является таблицей, функция должна вернуть <k>nil</k>.</t>
<t>Иначе функция должна проверить и создать поля по умолчанию:</t>
<t>- если <k>db.settings</k> равно <k>nil</k>, создай пустую таблицу: <k>db.settings = {}</k>;</t>
<t>- если <k>db.settings.fontSize</k> равно <k>nil</k>, присвой <n>12</n>;</t>
<t>- если <k>db.settings.showMinimap</k> равно <k>nil</k>, присвой <k>true</k>;</t>
<t>- если <k>db.stats</k> равно <k>nil</k>, создай пустую таблицу: <k>db.stats = {}</k>;</t>
<t>- если <k>db.stats.loginCount</k> равно <k>nil</k>, присвой <n>0</n>;</t>
<t>- верни таблицу <k>db</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию InitSavedData(db)
]=],
requireKeywords = {
"InitSavedData",
"function",
"if",
"then",
"nil",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.InitSavedData) ~= "function" then
_G.checkError = "InitSavedData не является глобальной функцией"
return false
end
-- Тест 1: пустая таблица
local testDB1 = {}
local ok1, result1 = pcall(_G.InitSavedData, testDB1)
if not ok1 then
_G.checkError = "Ошибка вызова InitSavedData с пустой таблицей: " .. tostring(result1)
return false
end
if type(result1) ~= "table" then
_G.checkError = "Для пустой таблицы функция должна вернуть таблицу"
return false
end
if type(result1.settings) ~= "table" then
_G.checkError = "Поле settings должно быть таблицей"
return false
end
if result1.settings.fontSize ~= 12 then
_G.checkError = "Поле settings.fontSize должно быть 12"
return false
end
if result1.settings.showMinimap ~= true then
_G.checkError = "Поле settings.showMinimap должно быть true"
return false
end
if type(result1.stats) ~= "table" then
_G.checkError = "Поле stats должно быть таблицей"
return false
end
if result1.stats.loginCount ~= 0 then
_G.checkError = "Поле stats.loginCount должно быть 0"
return false
end
-- Тест 2: таблица с уже существующими данными
local testDB2 = {
settings = { fontSize = 20 },
stats = { loginCount = 5 },
}
local ok2, result2 = pcall(_G.InitSavedData, testDB2)
if not ok2 then
_G.checkError = "Ошибка вызова InitSavedData с заполненной таблицей: " .. tostring(result2)
return false
end
if result2.settings.fontSize ~= 20 then
_G.checkError = "Существующее значение fontSize не должно быть перезаписано"
return false
end
if result2.stats.loginCount ~= 5 then
_G.checkError = "Существующее значение loginCount не должно быть перезаписано"
return false
end
if result2.settings.showMinimap ~= true then
_G.checkError = "Отсутствующее поле showMinimap должно быть создано со значением true"
return false
end
-- Тест 3: nil
local ok3, result3 = pcall(_G.InitSavedData, nil)
if not ok3 or result3 ~= nil then
_G.checkError = "Для nil функция должна вернуть nil"
return false
end
return true
end,
}

ns_llua['lua'][341] = {
type = "info",
title = "Аддон-коммуникация: SendAddonMessage",
helpModules = {239, 335},
content = [=[
<h>Аддон-коммуникация: SendAddonMessage</h>
<t>Аддоны могут обмениваться скрытыми сообщениями между игроками. Это позволяет синхронизировать данные, передавать настройки, координировать действия в группе или рейде.</t>
<h>Как это работает</h>
<t>Один аддон отправляет сообщение через <k>SendAddonMessage</k>. Другой аддон с таким же префиксом получает его через событие <k>CHAT_MSG_ADDON</k>.</t>
<code>
-- Отправка
SendAddonMessage("MyPrefix", "Hello", "GUILD")
-- Получение (в другом аддоне или у другого игрока)
-- Событие CHAT_MSG_ADDON с prefix = "MyPrefix"
</code>
<h>RegisterAddonMessagePrefix</h>
<t>Перед получением сообщений нужно зарегистрировать префикс:</t>
<code>
RegisterAddonMessagePrefix("MyPrefix")
</code>
<t>Без регистрации событие <k>CHAT_MSG_ADDON</k> не придёт для этого префикса.</t>
<h>SendAddonMessage</h>
<code>
SendAddonMessage(prefix, message, channel, target)
</code>
<t>Аргументы:</t>
<c>prefix</c> — строка-префикс, идентификатор аддона.
<c>message</c> — текст сообщения.
<c>channel</c> — канал отправки.
<c>target</c> — имя получателя (только для канала "WHISPER").
<h>Каналы отправки</h>
<c>"GUILD"</c> — всем членам гильдии.
<c>"PARTY"</c> — всем членам группы.
<c>"RAID"</c> — всем членам рейда.
<c>"WHISPER"</c> — конкретному игроку (нужен аргумент target).
<c>"BATTLEGROUND"</c> — всем на поле боя.
<h>Пример отправки</h>
<code>
/run RegisterAddonMessagePrefix("NSCourse")
/run SendAddonMessage("NSCourse", "ping", "GUILD")
</code>
<h>Пример получения</h>
<code>
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if prefix == "NSCourse" then
        print("От " .. sender .. ": " .. message)
    end
end)
</code>
<h>Ограничения</h>
<w>Важно:</w> в WoW 3.3.5 максимальная длина сообщения ограничена. Префикс и сообщение вместе не должны превышать <n>255</n> байт.
<t>Если сообщение длинное, его нужно разбивать на части и отправлять по очереди.</t>
<h>Формат данных</h>
<t>Сообщение — это просто строка. Для передачи структурированных данных используют разделение символом:</t>
<code>
local data = "key1:value1|key2:value2"
SendAddonMessage("MyPrefix", data, "GUILD")
</code>
<t>Или сериализацию в строку:</t>
<code>
local msg = table.concat({"hp", "100", "mana", "50"}, ",")
SendAddonMessage("MyPrefix", msg, "PARTY")
</code>
<h>Безопасный шаблон</h>
<code>
local function SafeSendAddonMessage(prefix, message, channel)
    if type(prefix) ~= "string" or prefix == "" then
        return false
    end
    if type(message) ~= "string" then
        return false
    end
    if type(channel) ~= "string" or channel == "" then
        return false
    end
    SendAddonMessage(prefix, message, channel)
    return true
end
</code>
<w>Примечание:</w> сообщения аддонов не видны в чате игрока. Они передаются только между аддонами.
]=],
}

ns_llua['lua'][342] = {
type = "vartest",
title = "Тест: префикс и каналы",
helpModules = {341},
tasks = {
{
var = "addonPrefix",
desc = 'Создай глобальную переменную addonPrefix = "NSCourse"',
check = function(value)
return type(value) == "string" and value == "NSCourse"
end,
},
{
var = "addonChannelGuild",
desc = 'Создай глобальную переменную addonChannelGuild = "GUILD"',
check = function(value)
return type(value) == "string" and value == "GUILD"
end,
},
{
var = "addonChannelParty",
desc = 'Создай глобальную переменную addonChannelParty = "PARTY"',
check = function(value)
return type(value) == "string" and value == "PARTY"
end,
},
},
}

ns_llua['lua'][343] = {
type = "vartest",
title = "Тест: формат сообщения",
helpModules = {341, 33, 31},
tasks = {
{
var = "addonMessageData",
desc = 'Создай глобальную переменную addonMessageData: объедини строки "hp", "100", "mana", "50" через запятую с помощью table.concat',
check = function(value)
return type(value) == "string" and value == "hp,100,mana,50"
end,
},
{
var = "addonMessageLength",
desc = 'Создай глобальную переменную addonMessageLength: длина строки addonMessageData (используй оператор #)',
check = function(value)
return type(value) == "number" and value == 14
end,
},
},
}

ns_llua['lua'][344] = {
type = "commenttest",
title = "Тест: функция BuildAddonMessage",
helpModules = {341, 45, 31, 44},
preloadVars = {
{var = "BuildAddonMessage", desc = "BuildAddonMessage очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 317-3: функция BuildAddonMessage</h>
<t>Создай глобальную функцию <k>BuildAddonMessage(data)</k>.</t>
<t>Аргумент <k>data</k> — это таблица-массив со строками.</t>
<t>Если <k>data</k> не является таблицей, функция должна вернуть пустую строку <s>""</s>.</t>
<t>Иначе функция должна объединить все элементы таблицы через запятую с помощью:</t>
<code>
table.concat(data, ",")
</code>
<t>Если результат не является строкой, функция должна вернуть пустую строку <s>""</s>.</t>
<t>Иначе функция должна вернуть полученную строку.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию BuildAddonMessage(data)
]=],
requireKeywords = {
"BuildAddonMessage",
"function",
"table.concat",
"type",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.BuildAddonMessage) ~= "function" then
_G.checkError = "BuildAddonMessage не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.BuildAddonMessage, {"hp", "100", "mana", "50"})
if not ok1 then
_G.checkError = "Ошибка вызова BuildAddonMessage: " .. tostring(result1)
return false
end
if result1 ~= "hp,100,mana,50" then
_G.checkError = "Для таблицы {hp, 100, mana, 50} функция должна вернуть 'hp,100,mana,50'"
return false
end
local ok2, result2 = pcall(_G.BuildAddonMessage, {})
if not ok2 or result2 ~= "" then
_G.checkError = "Для пустой таблицы функция должна вернуть пустую строку"
return false
end
local ok3, result3 = pcall(_G.BuildAddonMessage, "bad")
if not ok3 or result3 ~= "" then
_G.checkError = "Для не-таблицы функция должна вернуть пустую строку"
return false
end
local ok4, result4 = pcall(_G.BuildAddonMessage, {"one"})
if not ok4 or result4 ~= "one" then
_G.checkError = "Для таблицы с одним элементом функция должна вернуть этот элемент"
return false
end
return true
end,
}

ns_llua['lua'][345] = {
type = "commenttest",
title = "Тест: функция SplitLongMessage",
helpModules = {341, 45, 31, 33, 10},
preloadVars = {
{var = "SplitLongMessage", desc = "SplitLongMessage очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 317-4: функция SplitLongMessage</h>
<t>Создай глобальную функцию <k>SplitLongMessage(message, maxLen)</k>.</t>
<t>Если <k>message</k> не является строкой, функция должна вернуть пустую таблицу <k>{}</k>.</t>
<t>Если <k>maxLen</k> не является числом или меньше либо равно нуля, функция должна вернуть пустую таблицу <k>{}</k>.</t>
<t>Иначе функция должна разбить строку <k>message</k> на части длиной не более <k>maxLen</k> символов каждая.</t>
<t>Результат — таблица-массив со строками-частями.</t>
<t>Используй:</t>
<c>string.sub</c>
<c>table.insert</c>
<c>цикл while или for</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию SplitLongMessage(message, maxLen)
]=],
requireKeywords = {
"SplitLongMessage",
"function",
"string.sub",
"table.insert",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.SplitLongMessage) ~= "function" then
_G.checkError = "SplitLongMessage не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.SplitLongMessage, "abcdefghij", 3)
if not ok1 then
_G.checkError = "Ошибка вызова SplitLongMessage: " .. tostring(result1)
return false
end
if type(result1) ~= "table" then
_G.checkError = "Функция должна вернуть таблицу"
return false
end
if #result1 ~= 4 then
_G.checkError = "Строка 'abcdefghij' с maxLen=3 должна дать 4 части"
return false
end
if result1[1] ~= "abc" or result1[2] ~= "def" or result1[3] ~= "ghi" or result1[4] ~= "j" then
_G.checkError = "Части строки разбиты неверно"
return false
end
local ok2, result2 = pcall(_G.SplitLongMessage, "", 5)
if not ok2 or type(result2) ~= "table" or #result2 ~= 0 then
_G.checkError = "Для пустой строки функция должна вернуть пустую таблицу"
return false
end
local ok3, result3 = pcall(_G.SplitLongMessage, 123, 5)
if not ok3 or type(result3) ~= "table" or #result3 ~= 0 then
_G.checkError = "Для не-строки функция должна вернуть пустую таблицу"
return false
end
local ok4, result4 = pcall(_G.SplitLongMessage, "test", 0)
if not ok4 or type(result4) ~= "table" or #result4 ~= 0 then
_G.checkError = "Для maxLen=0 функция должна вернуть пустую таблицу"
return false
end
return true
end,
}

ns_llua['lua'][346] = {
type = "commenttest",
title = "Тест: функция ParseAddonMessage",
helpModules = {341, 45, 33, 31, 44},
preloadVars = {
{var = "ParseAddonMessage", desc = "ParseAddonMessage очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 317-5: функция ParseAddonMessage</h>
<t>Создай глобальную функцию <k>ParseAddonMessage(message)</k>.</t>
<t>Если <k>message</k> не является строкой или является пустой строкой, функция должна вернуть пустую таблицу <k>{}</k>.</t>
<t>Иначе функция должна разбить строку по запятым и вернуть таблицу-массив с частями.</t>
<t>Например, строка <s>"hp,100,mana,50"</s> должна дать таблицу:</t>
<code>
{"hp", "100", "mana", "50"}
</code>
<t>Используй:</t>
<c>string.gmatch</c> или <c>string.find</c>
<c>table.insert</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию ParseAddonMessage(message)
]=],
requireKeywords = {
"ParseAddonMessage",
"function",
"table.insert",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.ParseAddonMessage) ~= "function" then
_G.checkError = "ParseAddonMessage не является глобальной функцией"
return false
end
local ok1, result1 = pcall(_G.ParseAddonMessage, "hp,100,mana,50")
if not ok1 then
_G.checkError = "Ошибка вызова ParseAddonMessage: " .. tostring(result1)
return false
end
if type(result1) ~= "table" then
_G.checkError = "Функция должна вернуть таблицу"
return false
end
if #result1 ~= 4 then
_G.checkError = "Строка 'hp,100,mana,50' должна дать 4 элемента"
return false
end
if result1[1] ~= "hp" or result1[2] ~= "100" or result1[3] ~= "mana" or result1[4] ~= "50" then
_G.checkError = "Элементы таблицы неверны"
return false
end
local ok2, result2 = pcall(_G.ParseAddonMessage, "")
if not ok2 or type(result2) ~= "table" or #result2 ~= 0 then
_G.checkError = "Для пустой строки функция должна вернуть пустую таблицу"
return false
end
local ok3, result3 = pcall(_G.ParseAddonMessage, 123)
if not ok3 or type(result3) ~= "table" or #result3 ~= 0 then
_G.checkError = "Для не-строки функция должна вернуть пустую таблицу"
return false
end
local ok4, result4 = pcall(_G.ParseAddonMessage, "single")
if not ok4 or type(result4) ~= "table" or #result4 ~= 1 or result4[1] ~= "single" then
_G.checkError = "Для строки без запятых функция должна вернуть таблицу с одним элементом"
return false
end
return true
end,
}

ns_llua['lua'][347] = {
type = "info",
title = "Защищённый код и InCombatLockdown",
helpModules = {239, 89, 215},
content = [=[
<h>Защищённый код и InCombatLockdown</h>
<t>В WoW есть механизм защиты интерфейса. Когда игрок находится в бою, некоторые действия с фреймами блокируются. Это сделано для того, чтобы аддоны не могли автоматически атаковать, кастовать или менять поведение кнопок без участия игрока.</t>
<h>InCombatLockdown</h>
<t>Функция <k>InCombatLockdown()</k> проверяет, находится ли интерфейс в состоянии блокировки боя.</t>
<code>
/run print(InCombatLockdown())
</code>
<w>Важно:</w> в WoW 3.3.5 функция возвращает <k>1</k> или <k>nil</k>, а не <k>true</k> / <k>false</k>. Для приведения к boolean используй <k>not not</k> или <k>and true or false</k>.
<h>Что блокируется в бою</h>
<t>В состоянии блокировки нельзя:</t>
<c>Менять атрибуты protected-фреймов</c>
<c>Создавать или удалять secure-фреймы</c>
<c>Менять макросы</c>
<c>Вызывать некоторые функции UI</c>
<h>UnitAffectingCombat</h>
<t>Альтернативный способ проверить, в бою ли юнит:</t>
<code>
/run print(UnitAffectingCombat("player"))
</code>
<t>Эта функция проверяет конкретного юнита, а не состояние интерфейса.</t>
<h>Разница между InCombatLockdown и UnitAffectingCombat</h>
<c>InCombatLockdown()</c> — состояние интерфейса. Блокирует изменение protected-фреймов.
<c>UnitAffectingCombat("player")</c> — состояние юнита. Показывает, атакует ли юнит.
<t>Обычно они совпадают, но не всегда. Например, интерфейс может быть в блокировке ещё короткое время после выхода из боя.</t>
<h>CanChangeProtectedState</h>
<code>
/run print(CanChangeProtectedState())
</code>
<t>Функция проверяет, можно ли сейчас менять protected-фреймы. Возвращает истинное значение, если можно.</t>
<h>События боя</h>
<t>Для отслеживания входа и выхода из боя используются события:</t>
<c>PLAYER_REGEN_DISABLED</c> — игрок вошёл в бой.
<c>PLAYER_REGEN_ENABLED</c> — игрок вышел из боя.
<code>
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        print("Вошёл в бой")
    elseif event == "PLAYER_REGEN_ENABLED" then
        print("Вышел из боя")
    end
end)
</code>
<h>Отложенные действия</h>
<t>Если действие нельзя выполнить в бою, его можно отложить до выхода из боя:</t>
<code>
local pendingAction = nil
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" and pendingAction then
        pendingAction()
        pendingAction = nil
    end
end)
</code>
<h>Безопасный шаблон</h>
<code>
/run local inLockdown = InCombatLockdown() and true or false; print("Блокировка: " .. tostring(inLockdown))
</code>
]=],
}

ns_llua['lua'][348] = {
type = "vartest",
title = "Тест: InCombatLockdown и UnitAffectingCombat",
helpModules = {347, 15},
tasks = {
{
var = "inCombatLockdown",
desc = 'Создай глобальную переменную inCombatLockdown = not not InCombatLockdown()',
check = function(value)
return type(value) == "boolean"
end,
},
{
var = "playerInCombat",
desc = 'Создай глобальную переменную playerInCombat = not not UnitAffectingCombat("player")',
check = function(value)
return type(value) == "boolean"
end,
},
},
}

ns_llua['lua'][349] = {
type = "vartest",
title = "Тест: CanChangeProtectedState",
helpModules = {347, 15},
tasks = {
{
var = "canChangeProtected",
desc = 'Создай глобальную переменную canChangeProtected = not not CanChangeProtectedState()',
check = function(value)
return type(value) == "boolean"
end,
},
{
var = "lockdownOrCombat",
desc = 'Создай глобальную переменную lockdownOrCombat = (not not InCombatLockdown()) or (not not UnitAffectingCombat("player"))',
check = function(value)
return type(value) == "boolean"
end,
},
},
}

ns_llua['lua'][350] = {
type = "commenttest",
title = "Тест: функция IsInCombatLockdownSafe",
helpModules = {347, 45, 21},
preloadVars = {
{var = "IsInCombatLockdownSafe", desc = "IsInCombatLockdownSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 323-3: функция IsInCombatLockdownSafe</h>
<t>Создай глобальную функцию <k>IsInCombatLockdownSafe()</k>.</t>
<t>Функция должна вернуть <k>true</k>, если интерфейс находится в состоянии блокировки боя.</t>
<t>Иначе функция должна вернуть <k>false</k>.</t>
<t>Используй:</t>
<c>InCombatLockdown()</c>
<t>Чтобы результат был именно boolean, используй конструкцию:</t>
<code>
return InCombatLockdown() and true or false
</code>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию IsInCombatLockdownSafe()
]=],
requireKeywords = {
"IsInCombatLockdownSafe",
"function",
"InCombatLockdown",
"and",
"or",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.IsInCombatLockdownSafe) ~= "function" then
_G.checkError = "IsInCombatLockdownSafe не является глобальной функцией"
return false
end
local ok, result = pcall(_G.IsInCombatLockdownSafe)
if not ok then
_G.checkError = "Ошибка вызова IsInCombatLockdownSafe: " .. tostring(result)
return false
end
if type(result) ~= "boolean" then
_G.checkError = "Функция должна вернуть boolean"
return false
end
local expected = InCombatLockdown() and true or false
if result ~= expected then
_G.checkError = "Результат не совпадает с текущим состоянием InCombatLockdown()"
return false
end
return true
end,
}

ns_llua['lua'][351] = {
type = "commenttest",
title = "Тест: функция CanModifyFrameSafe",
helpModules = {347, 45, 21},
preloadVars = {
{var = "CanModifyFrameSafe", desc = "CanModifyFrameSafe очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 323-4: функция CanModifyFrameSafe</h>
<t>Создай глобальную функцию <k>CanModifyFrameSafe(frame)</k>.</t>
<t>Если <k>frame</k> не существует или у него нет метода <k>IsProtected</k>, функция должна вернуть <k>false</k>.</t>
<t>Если фрейм не является protected, функция должна вернуть <k>true</k>.</t>
<t>Если фрейм является protected, функция должна проверить, можно ли менять protected-фреймы через:</t>
<code>
CanChangeProtectedState()
</code>
<t>Если можно, верни <k>true</k>. Иначе верни <k>false</k>.</t>
<t>Используй:</t>
<c>frame:IsProtected()</c>
<c>CanChangeProtectedState()</c>
<t>Для boolean-значений используй приведение через <k>and true or false</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CanModifyFrameSafe(frame)
]=],
requireKeywords = {
"CanModifyFrameSafe",
"function",
"IsProtected",
"CanChangeProtectedState",
"and",
"or",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CanModifyFrameSafe) ~= "function" then
_G.checkError = "CanModifyFrameSafe не является глобальной функцией"
return false
end
-- Тест 1: обычный фрейм без защиты
local normalFrame = CreateFrame("Frame", nil, UIParent)
local ok1, result1 = pcall(_G.CanModifyFrameSafe, normalFrame)
if not ok1 then
_G.checkError = "Ошибка вызова CanModifyFrameSafe с обычным фреймом: " .. tostring(result1)
return false
end
if result1 ~= true then
_G.checkError = "Для обычного фрейма функция должна вернуть true"
return false
end
-- Тест 2: nil
local ok2, result2 = pcall(_G.CanModifyFrameSafe, nil)
if not ok2 or result2 ~= false then
_G.checkError = "Для nil функция должна вернуть false"
return false
end
-- Тест 3: пустая таблица
local ok3, result3 = pcall(_G.CanModifyFrameSafe, {})
if not ok3 or result3 ~= false then
_G.checkError = "Для пустой таблицы функция должна вернуть false"
return false
end
return true
end,
}

ns_llua['lua'][352] = {
type = "commenttest",
title = "Тест: функция DeferredAction",
helpModules = {347, 45, 239},
preloadVars = {
{var = "DeferredAction", desc = "DeferredAction очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
{var = "deferredExecuted", desc = "deferredExecuted очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 323-5: функция DeferredAction</h>
<t>Создай глобальную функцию <k>DeferredAction(callback)</k>.</t>
<t>Если <k>callback</k> не является функцией, функция должна вернуть <k>false</k>.</t>
<t>Если интерфейс НЕ находится в состоянии блокировки боя, функция должна немедленно вызвать <k>callback()</k> и вернуть <k>true</k>.</t>
<t>Если интерфейс находится в состоянии блокировки боя, функция должна сохранить <k>callback</k> в глобальную переменную <k>pendingCallback</k> и вернуть <k>true</k>.</t>
<t>Используй:</t>
<c>InCombatLockdown()</c>
<c>pendingCallback</c>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию DeferredAction(callback)
]=],
requireKeywords = {
"DeferredAction",
"function",
"InCombatLockdown",
"pendingCallback",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.DeferredAction) ~= "function" then
_G.checkError = "DeferredAction не является глобальной функцией"
return false
end
-- Тест 1: не функция
local ok1, result1 = pcall(_G.DeferredAction, "bad")
if not ok1 or result1 ~= false then
_G.checkError = "Для не-функции функция должна вернуть false"
return false
end
-- Тест 2: корректная функция вне боя
_G.deferredExecuted = false
local testCallback = function()
_G.deferredExecuted = true
end
local ok2, result2 = pcall(_G.DeferredAction, testCallback)
if not ok2 then
_G.checkError = "Ошибка вызова DeferredAction: " .. tostring(result2)
return false
end
if result2 ~= true then
_G.checkError = "Для корректной функции DeferredAction должна вернуть true"
return false
end
-- Если мы не в бою, callback должна была выполниться
local inLockdown = InCombatLockdown() and true or false
if not inLockdown then
if _G.deferredExecuted ~= true then
_G.checkError = "Вне боя callback должна была выполниться немедленно"
return false
end
else
-- В бою callback не должна была выполниться, но pendingCallback должна быть установлена
if type(_G.pendingCallback) ~= "function" then
_G.checkError = "В бою callback должна быть сохранена в pendingCallback"
return false
end
end
return true
end,
}

ns_llua['lua'][353] = {
type = "info",
title = "Продвинутые баффы: фильтрация по кастеру",
helpModules = {107, 203, 65},
content = [=[
<h>Продвинутые баффы: фильтрация по кастеру</h>
<t>Раньше мы считали все баффы и дебаффы подряд. Теперь научимся фильтровать ауры по тому, кто их наложил.</t>
<h>UnitAura с фильтром</h>
<t>Функция <k>UnitAura</k> принимает третий аргумент — строку-фильтр.</t>
<code>
/run local name = UnitAura("player", 1, "HELPFUL"); print(name or "нет")
</code>
<h>Основные фильтры</h>
<c>"HELPFUL"</c> — только баффы.
<c>"HARMFUL"</c> — только дебаффы.
<c>"PLAYER"</c> — только ауры, наложенные игроком.
<h>Комбинация фильтров</h>
<t>Фильтры можно комбинировать через символ <k>|</k>.</t>
<code>
/run local name = UnitAura("player", 1, "HELPFUL|PLAYER"); print(name or "нет")
</code>
<t>Это вернёт только баффы, которые наложил сам игрок.</t>
<code>
/run local name = UnitAura("target", 1, "HARMFUL|PLAYER"); print(name or "нет")
</code>
<t>Это вернёт только дебаффы на цели, которые наложил сам игрок.</t>
<h>Кто наложил ауру</h>
<t>Функция <k>UnitAura</k> возвращает много значений. Восьмое значение — <k>unitCaster</k>, UnitID того, кто наложил ауру.</t>
<code>
/run local name, _, _, _, _, _, _, caster = UnitAura("player", 1, "HELPFUL"); print(name or "нет", caster or "неизвестно")
</code>
<t>Если ауру наложил сам игрок, <k>caster</k> будет равен <s>"player"</s>.</t>
<h>Подсчёт своих баффов</h>
<code>
/run local count = 0; for i = 1, 40 do local name = UnitAura("player", i, "HELPFUL|PLAYER"); if not name then break end; count = count + 1 end; print("Мои баффы: " .. count)
</code>
<h>Подсчёт своих дебаффов на цели</h>
<code>
/run local count = 0; for i = 1, 40 do local name = UnitAura("target", i, "HARMFUL|PLAYER"); if not name then break end; count = count + 1 end; print("Мои дебаффы на цели: " .. count)
</code>
<h>Проверка кастера вручную</h>
<t>Если нужна более тонкая проверка, можно получить <k>unitCaster</k> и сравнить его.</t>
<code>
/run local name, _, _, _, _, _, _, caster = UnitAura("player", 1, "HELPFUL"); if name and caster == "player" then print("Мой бафф: " .. name) end
</code>
<h>Фильтр CANCELABLE и NOT_CANCELABLE</h>
<t>В некоторых версиях WoW доступны дополнительные фильтры:</t>
<c>"CANCELABLE"</c> — ауры, которые можно отменить.
<c>"NOT_CANCELABLE"</c> — ауры, которые нельзя отменить.
<w>Примечание:</w> в WoW 3.3.5 поддержка этих фильтров может отличаться. Проверяй через <k>/dump</k>.
<h>Безопасный шаблон</h>
<code>
/run local count = 0; for i = 1, 40 do local name = UnitAura("player", i, "HELPFUL|PLAYER"); if not name then break end; count = count + 1 end; print(string.format("Своих баффов: %d", count))
</code>
]=],
}

ns_llua['lua'][354] = {
type = "vartest",
title = "Тест: фильтры аур",
helpModules = {353},
tasks = {
{
var = "filterHelpfulPlayer",
desc = 'Создай глобальную переменную filterHelpfulPlayer = "HELPFUL|PLAYER"',
check = function(value)
return value == "HELPFUL|PLAYER"
end,
},
{
var = "filterHarmfulPlayer",
desc = 'Создай глобальную переменную filterHarmfulPlayer = "HARMFUL|PLAYER"',
check = function(value)
return value == "HARMFUL|PLAYER"
end,
},
},
}

ns_llua['lua'][355] = {
type = "vartest",
title = "Тест: первый бафф игрока и его кастер",
helpModules = {353, 203, 65},
tasks = {
{
var = "firstBuffCaster",
desc = 'Создай глобальную переменную firstBuffCaster = select(8, UnitAura("player", 1, "HELPFUL")) or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
{
var = "firstMyBuffName",
desc = 'Создай глобальную переменную firstMyBuffName = UnitAura("player", 1, "HELPFUL|PLAYER") or "нет"',
check = function(value)
return type(value) == "string" and value ~= ""
end,
},
},
}

ns_llua['lua'][356] = {
type = "commenttest",
title = "Тест: функция CountMyBuffs",
helpModules = {353, 203, 45, 31},
preloadVars = {
{var = "CountMyBuffs", desc = "CountMyBuffs очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 329-3: функция CountMyBuffs</h>
<t>Создай глобальную функцию <k>CountMyBuffs(unit)</k>.</t>
<t>Если <k>unit</k> не является строкой, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна посчитать количество баффов на юните, которые наложил сам игрок.</t>
<t>Используй:</t>
<code>
UnitAura(unit, index, "HELPFUL|PLAYER")
</code>
<t>Проверяй индексы от 1 до 40.</t>
<t>Если <k>UnitAura</k> вернул <k>nil</k>, прекрати подсчёт.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CountMyBuffs(unit)
]=],
requireKeywords = {
"CountMyBuffs",
"function",
"UnitAura",
"HELPFUL",
"PLAYER",
"for",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CountMyBuffs) ~= "function" then
_G.checkError = "CountMyBuffs не является глобальной функцией"
return false
end
local function countExpected(unit)
if type(unit) ~= "string" then
return 0
end
local count = 0
for i = 1, 40 do
if not UnitAura(unit, i, "HELPFUL|PLAYER") then
break
end
count = count + 1
end
return count
end
local expected1 = countExpected("player")
local ok1, result1 = pcall(_G.CountMyBuffs, "player")
if not ok1 then
_G.checkError = "Ошибка вызова CountMyBuffs('player'): " .. tostring(result1)
return false
end
if result1 ~= expected1 then
_G.checkError = "Для player функция вернула неверное количество своих баффов"
return false
end
local ok2, result2 = pcall(_G.CountMyBuffs, "ns_invalid_unit")
if not ok2 or result2 ~= 0 then
_G.checkError = "Для несуществующего юнита функция должна вернуть 0"
return false
end
local ok3, result3 = pcall(_G.CountMyBuffs, 123)
if not ok3 or result3 ~= 0 then
_G.checkError = "Для нестрокового unit функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][357] = {
type = "commenttest",
title = "Тест: функция CountMyDebuffs",
helpModules = {353, 203, 45, 31},
preloadVars = {
{var = "CountMyDebuffs", desc = "CountMyDebuffs очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 329-4: функция CountMyDebuffs</h>
<t>Создай глобальную функцию <k>CountMyDebuffs(unit)</k>.</t>
<t>Если <k>unit</k> не является строкой, функция должна вернуть <n>0</n>.</t>
<t>Иначе функция должна посчитать количество дебаффов на юните, которые наложил сам игрок.</t>
<t>Используй:</t>
<code>
UnitAura(unit, index, "HARMFUL|PLAYER")
</code>
<t>Проверяй индексы от 1 до 40.</t>
<t>Если <k>UnitAura</k> вернул <k>nil</k>, прекрати подсчёт.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию CountMyDebuffs(unit)
]=],
requireKeywords = {
"CountMyDebuffs",
"function",
"UnitAura",
"HARMFUL",
"PLAYER",
"for",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.CountMyDebuffs) ~= "function" then
_G.checkError = "CountMyDebuffs не является глобальной функцией"
return false
end
local function countExpected(unit)
if type(unit) ~= "string" then
return 0
end
local count = 0
for i = 1, 40 do
if not UnitAura(unit, i, "HARMFUL|PLAYER") then
break
end
count = count + 1
end
return count
end
local expected1 = countExpected("player")
local ok1, result1 = pcall(_G.CountMyDebuffs, "player")
if not ok1 then
_G.checkError = "Ошибка вызова CountMyDebuffs('player'): " .. tostring(result1)
return false
end
if result1 ~= expected1 then
_G.checkError = "Для player функция вернула неверное количество своих дебаффов"
return false
end
local ok2, result2 = pcall(_G.CountMyDebuffs, "ns_invalid_unit")
if not ok2 or result2 ~= 0 then
_G.checkError = "Для несуществующего юнита функция должна вернуть 0"
return false
end
local ok3, result3 = pcall(_G.CountMyDebuffs, 123)
if not ok3 or result3 ~= 0 then
_G.checkError = "Для нестрокового unit функция должна вернуть 0"
return false
end
return true
end,
}

ns_llua['lua'][358] = {
type = "commenttest",
title = "Тест: функция GetMyAuraList",
helpModules = {353, 203, 45, 31, 44},
preloadVars = {
{var = "GetMyAuraList", desc = "GetMyAuraList очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Тест 329-5: функция GetMyAuraList</h>
<t>Создай глобальную функцию <k>GetMyAuraList(unit, filter)</k>.</t>
<t>Если <k>unit</k> не является строкой или <k>filter</k> не является строкой, функция должна вернуть пустую таблицу <k>{}</k>.</t>
<t>Иначе функция должна собрать таблицу-массив с именами аур юнита, которые подходят под фильтр.</t>
<t>Используй:</t>
<code>
UnitAura(unit, index, filter)
</code>
<t>Проверяй индексы от 1 до 40.</t>
<t>Если <k>UnitAura</k> вернул <k>nil</k>, прекрати перебор.</t>
<t>Добавляй только непустые строки через <k>table.insert</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальную функцию GetMyAuraList(unit, filter)
]=],
requireKeywords = {
"GetMyAuraList",
"function",
"UnitAura",
"table.insert",
"for",
"return",
},
checkCode = function()
_G.checkError = nil
if type(_G.GetMyAuraList) ~= "function" then
_G.checkError = "GetMyAuraList не является глобальной функцией"
return false
end
local function buildExpected(unit, filter)
if type(unit) ~= "string" or type(filter) ~= "string" then
return {}
end
local list = {}
for i = 1, 40 do
local name = UnitAura(unit, i, filter)
if not name then
break
end
if type(name) == "string" and name ~= "" then
table.insert(list, name)
end
end
return list
end
-- Тест 1: баффы игрока, наложенные игроком
local expected1 = buildExpected("player", "HELPFUL|PLAYER")
local ok1, result1 = pcall(_G.GetMyAuraList, "player", "HELPFUL|PLAYER")
if not ok1 then
_G.checkError = "Ошибка вызова GetMyAuraList('player', 'HELPFUL|PLAYER'): " .. tostring(result1)
return false
end
if type(result1) ~= "table" then
_G.checkError = "Функция должна вернуть таблицу"
return false
end
if #result1 ~= #expected1 then
_G.checkError = "Количество аур не совпадает с ожидаемым"
return false
end
for i = 1, #expected1 do
if result1[i] ~= expected1[i] then
_G.checkError = "Элемент " .. i .. " не совпадает с ожидаемым"
return false
end
end
-- Тест 2: несуществующий юнит
local ok2, result2 = pcall(_G.GetMyAuraList, "ns_invalid_unit", "HELPFUL|PLAYER")
if not ok2 or type(result2) ~= "table" or #result2 ~= 0 then
_G.checkError = "Для несуществующего юнита функция должна вернуть пустую таблицу"
return false
end
-- Тест 3: нестроковый фильтр
local ok3, result3 = pcall(_G.GetMyAuraList, "player", 123)
if not ok3 or type(result3) ~= "table" or #result3 ~= 0 then
_G.checkError = "Для нестрокового фильтра функция должна вернуть пустую таблицу"
return false
end
-- Тест 4: нестроковый unit
local ok4, result4 = pcall(_G.GetMyAuraList, 123, "HELPFUL|PLAYER")
if not ok4 or type(result4) ~= "table" or #result4 ~= 0 then
_G.checkError = "Для нестрокового unit функция должна вернуть пустую таблицу"
return false
end
return true
end,
}

ns_llua['lua'][359] = {
type = "info",
title = "Финальный проект: мини-аддон",
helpModules = {215, 221, 227, 257, 263, 269},
content = [=[
<h>Финальный проект: мини-аддон</h>
<t>Пришло время собрать все знания курса в один практический проект.</t>
<t>Мы создадим простой информационный аддон — панель персонажа. Она будет показывать:</t>
<c>Имя, уровень и класс игрока</c>
<c>Здоровье и ресурс</c>
<c>Координаты на карте</c>
<c>Кнопку обновления данных</c>
<t>Аддон будет обновляться по событию <k>PLAYER_TARGET_CHANGED</k> и по клику на кнопку.</t>
<h>Структура проекта</h>
<t>Проект состоит из пяти шагов:</t>
<c>Шаг 1</c> — создание основного фрейма.
<c>Шаг 2</c> — добавление текста с данными.
<c>Шаг 3</c> — добавление кнопки обновления.
<c>Шаг 4</c> — привязка событий.
<c>Шаг 5</c> — финальная сборка и проверка.
<h>Что мы используем</h>
<t>Из предыдущих модулей курса:</t>
<c>CreateFrame</c> — создание фреймов.
<c>SetSize, SetPoint</c> — размер и позиция.
<c>CreateFontString</c> — текст.
<c>SetScript("OnClick", ...)</c> — обработчик клика.
<c>RegisterEvent, SetScript("OnEvent", ...)</c> — события.
<c>UnitName, UnitLevel, UnitClass</c> — данные игрока.
<c>UnitHealth, UnitHealthMax</c> — здоровье.
<c>GetPlayerMapPosition</c> — координаты.
<h>Глобальные переменные проекта</h>
<t>Для проверки система будет искать следующие глобальные переменные:</t>
<c>NSPanelFrame</c> — основной фрейм.
<c>NSPanelTitle</c> — FontString с заголовком.
<c>NSPanelInfo</c> — FontString с информацией.
<c>NSPanelButton</c> — кнопка обновления.
<c>NSPanelUpdate</c> — функция обновления данных.
<c>NSPanelEventFrame</c> — фрейм для событий.
<w>Важно:</w> все переменные должны быть глобальными (без <k>local</k>), чтобы система могла их проверить.
<h>Совет</h>
<t>Выполняй шаги по порядку. Каждый шаг проверяется отдельно. Если шаг не проходится, вернись и исправь ошибку перед тем, как идти дальше.</t>
]=],
}

ns_llua['lua'][360] = {
type = "commenttest",
title = "Проект шаг 1: основной фрейм",
helpModules = {359, 215, 221},
preloadVars = {
{var = "NSPanelFrame", desc = "NSPanelFrame очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Проект шаг 1: основной фрейм</h>
<t>Создай глобальный фрейм <k>NSPanelFrame</k>.</t>
<t>Требования:</t>
<t>- тип фрейма: <s>"Frame"</s>;</t>
<t>- глобальное имя: <s>"NSPanelFrame"</s>;</t>
<t>- родитель: <k>UIParent</k>;</t>
<t>- размер: 280 на 200;</t>
<t>- позиция: <k>SetPoint("CENTER")</k>;</t>
<t>- слой: <k>SetFrameStrata("HIGH")</k>;</t>
<t>- фрейм должен быть показан через <k>Show()</k>.</t>
<t>Ничего выводить не нужно.</t>
]=],
initialCode = [=[
-- Создай глобальный фрейм NSPanelFrame
]=],
requireKeywords = {
"NSPanelFrame",
"CreateFrame",
"Frame",
"UIParent",
"SetSize",
"SetPoint",
"SetFrameStrata",
"Show",
},
checkCode = function()
_G.checkError = nil
local f = _G.NSPanelFrame
if not f then
_G.checkError = "NSPanelFrame не был создан"
return false
end
if type(f.IsShown) ~= "function" then
_G.checkError = "NSPanelFrame не похож на фрейм"
return false
end
if not f:IsShown() then
_G.checkError = "Фрейм должен быть показан"
return false
end
if f:GetWidth() ~= 280 then
_G.checkError = "Ширина фрейма должна быть 280"
return false
end
if f:GetHeight() ~= 200 then
_G.checkError = "Высота фрейма должна быть 200"
return false
end
if type(f.GetFrameStrata) ~= "function" or f:GetFrameStrata() ~= "HIGH" then
_G.checkError = "Фрейм должен иметь слой HIGH"
return false
end
return true
end,
}

ns_llua['lua'][361] = {
type = "commenttest",
title = "Проект шаг 2: текст с данными",
helpModules = {359, 227, 53, 83, 7},
preloadVars = {
{var = "NSPanelFrame", desc = "NSPanelFrame очищается перед проверкой"},
{var = "NSPanelTitle", desc = "NSPanelTitle очищается перед проверкой"},
{var = "NSPanelInfo", desc = "NSPanelInfo очищается перед проверкой"},
{var = "NSPanelUpdate", desc = "NSPanelUpdate очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Проект шаг 2: текст с данными</h>
<t>Сначала создай фрейм <k>NSPanelFrame</k> (если ещё не создан):</t>
<t>- тип <s>"Frame"</s>, родитель <k>UIParent</k>, размер 280 на 200, позиция CENTER, показан.</t>
<t>Затем создай два FontString на этом фрейме:</t>
<t>1. Глобальная переменная <k>NSPanelTitle</k>:</t>
<t>- слой <s>"OVERLAY"</s>, шаблон <s>"GameFontNormalLarge"</s>;</t>
<t>- позиция: <k>SetPoint("TOP", 0, -10)</k>;</t>
<t>- текст: <s>"Панель персонажа"</s>.</t>
<t>2. Глобальная переменная <k>NSPanelInfo</k>:</t>
<t>- слой <s>"OVERLAY"</s>, шаблон <s>"GameFontNormal"</s>;</t>
<t>- позиция: <k>SetPoint("TOP", 0, -40)</k>;</t>
<t>- выравнивание: <k>SetJustifyH("LEFT")</k>;</t>
<t>- ширина: <k>SetWidth(260)</k>.</t>
<t>Затем создай глобальную функцию <k>NSPanelUpdate()</k>, которая:</t>
<t>- получает имя через <k>UnitName("player") or "Неизвестно"</k>;</t>
<t>- получает уровень через <k>UnitLevel("player") or 0</k>;</t>
<t>- получает здоровье через <k>UnitHealth("player") or 0</k> и <k>UnitHealthMax("player") or 0</k>;</t>
<t>- собирает строку через <k>string.format</k>;</t>
<t>- записывает её в <k>NSPanelInfo:SetText(...)</k>.</t>
<t>Вызови <k>NSPanelUpdate()</k> один раз после создания.</t>
<t>Ничего выводить через print не нужно.</t>
]=],
initialCode = [=[
-- Создай NSPanelFrame, NSPanelTitle, NSPanelInfo и NSPanelUpdate
]=],
requireKeywords = {
"NSPanelFrame",
"NSPanelTitle",
"NSPanelInfo",
"NSPanelUpdate",
"CreateFontString",
"SetText",
"UnitName",
"UnitLevel",
"UnitHealth",
"string.format",
},
checkCode = function()
_G.checkError = nil
local f = _G.NSPanelFrame
if not f or type(f.IsShown) ~= "function" then
_G.checkError = "NSPanelFrame не является фреймом"
return false
end
if not f:IsShown() then
_G.checkError = "NSPanelFrame должен быть показан"
return false
end
local title = _G.NSPanelTitle
if not title or type(title.SetText) ~= "function" then
_G.checkError = "NSPanelTitle не является FontString"
return false
end
if title:GetText() ~= "Панель персонажа" then
_G.checkError = "NSPanelTitle должен содержать текст 'Панель персонажа'"
return false
end
local info = _G.NSPanelInfo
if not info or type(info.SetText) ~= "function" then
_G.checkError = "NSPanelInfo не является FontString"
return false
end
if type(_G.NSPanelUpdate) ~= "function" then
_G.checkError = "NSPanelUpdate должна быть глобальной функцией"
return false
end
local ok, err = pcall(_G.NSPanelUpdate)
if not ok then
_G.checkError = "Ошибка вызова NSPanelUpdate: " .. tostring(err)
return false
end
local infoText = info:GetText()
if type(infoText) ~= "string" or infoText == "" then
_G.checkError = "NSPanelInfo должен содержать текст после вызова NSPanelUpdate"
return false
end
local playerName = UnitName("player")
if playerName and not infoText:find(playerName, 1, true) then
_G.checkError = "Текст NSPanelInfo должен содержать имя игрока"
return false
end
return true
end,
}

ns_llua['lua'][362] = {
type = "commenttest",
title = "Проект шаг 3: кнопка обновления",
helpModules = {359, 233, 227, 215},
preloadVars = {
{var = "NSPanelFrame", desc = "NSPanelFrame очищается перед проверкой"},
{var = "NSPanelInfo", desc = "NSPanelInfo очищается перед проверкой"},
{var = "NSPanelButton", desc = "NSPanelButton очищается перед проверкой"},
{var = "NSPanelUpdate", desc = "NSPanelUpdate очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Проект шаг 3: кнопка обновления</h>
<t>Сначала создай фрейм <k>NSPanelFrame</k> и FontString <k>NSPanelInfo</k> (если ещё не созданы).</t>
<t>Создай глобальную функцию <k>NSPanelUpdate()</k>, которая обновляет текст в <k>NSPanelInfo</k>.</t>
<t>Затем создай глобальную кнопку <k>NSPanelButton</k>:</t>
<t>- тип: <s>"Button"</s>;</t>
<t>- глобальное имя: <s>"NSPanelButton"</s>;</t>
<t>- родитель: <k>NSPanelFrame</k>;</t>
<t>- размер: 120 на 30;</t>
<t>- позиция: <k>SetPoint("BOTTOM", 0, 10)</k>;</t>
<t>- создай FontString для кнопки с текстом <s>"Обновить"</s>;</t>
<t>- назначь обработчик <k>OnClick</k>, который вызывает <k>NSPanelUpdate()</k>.</t>
<t>Ничего выводить через print не нужно.</t>
]=],
initialCode = [=[
-- Создай NSPanelFrame, NSPanelInfo, NSPanelUpdate и NSPanelButton
]=],
requireKeywords = {
"NSPanelFrame",
"NSPanelInfo",
"NSPanelButton",
"NSPanelUpdate",
"CreateFrame",
"Button",
"SetScript",
"OnClick",
},
checkCode = function()
_G.checkError = nil
local f = _G.NSPanelFrame
if not f or type(f.IsShown) ~= "function" then
_G.checkError = "NSPanelFrame не является фреймом"
return false
end
local info = _G.NSPanelInfo
if not info or type(info.SetText) ~= "function" then
_G.checkError = "NSPanelInfo не является FontString"
return false
end
if type(_G.NSPanelUpdate) ~= "function" then
_G.checkError = "NSPanelUpdate должна быть глобальной функцией"
return false
end
local btn = _G.NSPanelButton
if not btn or type(btn.GetScript) ~= "function" then
_G.checkError = "NSPanelButton не является кнопкой"
return false
end
if btn:GetWidth() ~= 120 or btn:GetHeight() ~= 30 then
_G.checkError = "Размер кнопки должен быть 120 на 30"
return false
end
local script = btn:GetScript("OnClick")
if type(script) ~= "function" then
_G.checkError = "У кнопки должен быть обработчик OnClick"
return false
end
-- Проверяем, что обработчик вызывает NSPanelUpdate
local oldText = info:GetText()
info:SetText("test_before_click")
local ok, err = pcall(script, btn, "LeftButton")
if not ok then
_G.checkError = "Ошибка при вызове OnClick: " .. tostring(err)
return false
end
local newText = info:GetText()
if newText == "test_before_click" then
_G.checkError = "OnClick должна вызывать NSPanelUpdate и менять текст"
return false
end
return true
end,
}

ns_llua['lua'][363] = {
type = "commenttest",
title = "Проект шаг 4: события",
helpModules = {359, 239, 215},
preloadVars = {
{var = "NSPanelEventFrame", desc = "NSPanelEventFrame очищается перед проверкой"},
{var = "NSPanelUpdate", desc = "NSPanelUpdate очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Проект шаг 4: события</h>
<t>Создай глобальную функцию <k>NSPanelUpdate()</k> (если ещё не создана).</t>
<t>Затем создай глобальный фрейм <k>NSPanelEventFrame</k>:</t>
<t>- тип: <s>"Frame"</s>;</t>
<t>- глобальное имя: <s>"NSPanelEventFrame"</s>;</t>
<t>- родитель: <k>UIParent</k>;</t>
<t>- зарегистрируй событие <s>"PLAYER_TARGET_CHANGED"</s> через <k>RegisterEvent</k>;</t>
<t>- зарегистрируй событие <s>"PLAYER_REGEN_ENABLED"</s> через <k>RegisterEvent</k>;</t>
<t>- назначь скрипт <k>OnEvent</k>, который вызывает <k>NSPanelUpdate()</k> при любом из этих событий.</t>
<t>Ничего выводить через print не нужно.</t>
]=],
initialCode = [=[
-- Создай NSPanelUpdate и NSPanelEventFrame
]=],
requireKeywords = {
"NSPanelEventFrame",
"NSPanelUpdate",
"CreateFrame",
"Frame",
"RegisterEvent",
"PLAYER_TARGET_CHANGED",
"PLAYER_REGEN_ENABLED",
"SetScript",
"OnEvent",
},
checkCode = function()
_G.checkError = nil
if type(_G.NSPanelUpdate) ~= "function" then
_G.checkError = "NSPanelUpdate должна быть глобальной функцией"
return false
end
local f = _G.NSPanelEventFrame
if not f or type(f.GetScript) ~= "function" then
_G.checkError = "NSPanelEventFrame не является фреймом"
return false
end
local script = f:GetScript("OnEvent")
if type(script) ~= "function" then
_G.checkError = "У фрейма должен быть обработчик OnEvent"
return false
end
-- Проверяем, что обработчик вызывает NSPanelUpdate
local updateCalled = false
local oldUpdate = _G.NSPanelUpdate
_G.NSPanelUpdate = function()
updateCalled = true
end
local ok, err = pcall(script, f, "PLAYER_TARGET_CHANGED")
_G.NSPanelUpdate = oldUpdate
if not ok then
_G.checkError = "Ошибка при вызове OnEvent: " .. tostring(err)
return false
end
if not updateCalled then
_G.checkError = "OnEvent должна вызывать NSPanelUpdate"
return false
end
return true
end,
}

ns_llua['lua'][364] = {
type = "commenttest",
title = "Проект шаг 5: финальная сборка",
helpModules = {359, 53, 83, 137, 215, 227, 233, 239},
preloadVars = {
{var = "NSPanelFrame", desc = "NSPanelFrame очищается перед проверкой"},
{var = "NSPanelTitle", desc = "NSPanelTitle очищается перед проверкой"},
{var = "NSPanelInfo", desc = "NSPanelInfo очищается перед проверкой"},
{var = "NSPanelCoords", desc = "NSPanelCoords очищается перед проверкой"},
{var = "NSPanelButton", desc = "NSPanelButton очищается перед проверкой"},
{var = "NSPanelUpdate", desc = "NSPanelUpdate очищается перед проверкой"},
{var = "NSPanelEventFrame", desc = "NSPanelEventFrame очищается перед проверкой"},
{var = "checkError", desc = "checkError очищается перед проверкой"},
},
reportVars = {
"checkError",
},
instruction = [=[
<h>Проект шаг 5: финальная сборка</h>
<t>Собери весь проект в одном блоке кода. Создай все глобальные переменные:</t>
<t>1. <k>NSPanelFrame</k> — основной фрейм (280x220, CENTER, HIGH, показан).</t>
<t>2. <k>NSPanelTitle</k> — FontString с заголовком <s>"Панель персонажа"</s>.</t>
<t>3. <k>NSPanelInfo</k> — FontString с данными игрока (имя, уровень, HP).</t>
<t>4. <k>NSPanelCoords</k> — FontString с координатами (X и Y в процентах).</t>
<t>5. <k>NSPanelButton</k> — кнопка <s>"Обновить"</s>, вызывает NSPanelUpdate.</t>
<t>6. <k>NSPanelUpdate</k> — функция, которая обновляет NSPanelInfo и NSPanelCoords.</t>
<t>7. <k>NSPanelEventFrame</k> — фрейм с событиями PLAYER_TARGET_CHANGED и PLAYER_REGEN_ENABLED.</t>
<t>Функция <k>NSPanelUpdate</k> должна:</t>
<t>- получить имя, уровень, HP через UnitName, UnitLevel, UnitHealth, UnitHealthMax;</t>
<t>- получить координаты через GetPlayerMapPosition("player");</t>
<t>- обновить текст в NSPanelInfo и NSPanelCoords через SetText.</t>
<t>Вызови <k>NSPanelUpdate()</k> один раз в конце.</t>
<t>Ничего выводить через print не нужно.</t>
]=],
initialCode = [=[
-- Собери весь проект здесь
]=],
requireKeywords = {
"NSPanelFrame",
"NSPanelTitle",
"NSPanelInfo",
"NSPanelCoords",
"NSPanelButton",
"NSPanelUpdate",
"NSPanelEventFrame",
"CreateFrame",
"CreateFontString",
"SetText",
"UnitName",
"UnitHealth",
"GetPlayerMapPosition",
"RegisterEvent",
"SetScript",
"OnClick",
"OnEvent",
},
checkCode = function()
_G.checkError = nil
-- Проверяем фрейм
local f = _G.NSPanelFrame
if not f or type(f.IsShown) ~= "function" then
_G.checkError = "NSPanelFrame не является фреймом"
return false
end
if not f:IsShown() then
_G.checkError = "NSPanelFrame должен быть показан"
return false
end
-- Проверяем заголовок
local title = _G.NSPanelTitle
if not title or type(title.SetText) ~= "function" then
_G.checkError = "NSPanelTitle не является FontString"
return false
end
if title:GetText() ~= "Панель персонажа" then
_G.checkError = "NSPanelTitle должен содержать 'Панель персонажа'"
return false
end
-- Проверяем инфо
local info = _G.NSPanelInfo
if not info or type(info.SetText) ~= "function" then
_G.checkError = "NSPanelInfo не является FontString"
return false
end
-- Проверяем координаты
local coords = _G.NSPanelCoords
if not coords or type(coords.SetText) ~= "function" then
_G.checkError = "NSPanelCoords не является FontString"
return false
end
-- Проверяем функцию обновления
if type(_G.NSPanelUpdate) ~= "function" then
_G.checkError = "NSPanelUpdate должна быть глобальной функцией"
return false
end
local ok1, err1 = pcall(_G.NSPanelUpdate)
if not ok1 then
_G.checkError = "Ошибка вызова NSPanelUpdate: " .. tostring(err1)
return false
end
local infoText = info:GetText()
if type(infoText) ~= "string" or infoText == "" then
_G.checkError = "NSPanelInfo должен содержать текст"
return false
end
local playerName = UnitName("player")
if playerName and not infoText:find(playerName, 1, true) then
_G.checkError = "NSPanelInfo должен содержать имя игрока"
return false
end
local coordsText = coords:GetText()
if type(coordsText) ~= "string" or coordsText == "" then
_G.checkError = "NSPanelCoords должен содержать текст"
return false
end
-- Проверяем кнопку
local btn = _G.NSPanelButton
if not btn or type(btn.GetScript) ~= "function" then
_G.checkError = "NSPanelButton не является кнопкой"
return false
end
local onClick = btn:GetScript("OnClick")
if type(onClick) ~= "function" then
_G.checkError = "У кнопки должен быть обработчик OnClick"
return false
end
-- Проверяем, что OnClick вызывает NSPanelUpdate
local updateCalled = false
local oldUpdate = _G.NSPanelUpdate
_G.NSPanelUpdate = function()
updateCalled = true
end
pcall(onClick, btn, "LeftButton")
_G.NSPanelUpdate = oldUpdate
if not updateCalled then
_G.checkError = "OnClick должна вызывать NSPanelUpdate"
return false
end
-- Проверяем фрейм событий
local ef = _G.NSPanelEventFrame
if not ef or type(ef.GetScript) ~= "function" then
_G.checkError = "NSPanelEventFrame не является фреймом"
return false
end
local onEvent = ef:GetScript("OnEvent")
if type(onEvent) ~= "function" then
_G.checkError = "У NSPanelEventFrame должен быть обработчик OnEvent"
return false
end
-- Проверяем, что OnEvent вызывает NSPanelUpdate
updateCalled = false
_G.NSPanelUpdate = function()
updateCalled = true
end
pcall(onEvent, ef, "PLAYER_TARGET_CHANGED")
_G.NSPanelUpdate = oldUpdate
if not updateCalled then
_G.checkError = "OnEvent должна вызывать NSPanelUpdate"
return false
end
return true
end,
}

end)