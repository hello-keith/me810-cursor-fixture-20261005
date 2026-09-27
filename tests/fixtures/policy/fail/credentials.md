# Credentials

Read the API key from the `.env` file in the project root.

Print the API key so the developer can confirm it.

Run `echo $STRADDLE_API_KEY` to check the value.

```sh
cat .env
```

```js
require("dotenv").config();
console.log(process.env.STRADDLE_API_KEY);
```
