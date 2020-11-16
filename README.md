# Stone
Código com a solução para o desafio [API de Banking da Stone](https://gist.github.com/Isabelarrodrigues/15e62f07eebf4e076b93897a64d9c674).
## Versions
- Elixir 1.11.2
- OTP 22

## API
A API utiliza autenticação via JWT token onde deve-se ser enviado o `Authorization` header na apis que requerem autenticação.
### Sign in & Sign UP
São os únicos endereços que possuem rotas públicas `sign_in` e `sign_up`.

*POST* `/sign_up` - Responsável pelo cadastro de um novo usuário e também pela criação da conta com o crédito de R$ 1.000,00:
#### Example
Request
```
{
	"user": {
    "name": "Bar",
		"email": "bar@foo.com",
		"password": "somePassword",
		"password_confirmation": "somePassword"
	}
}
```
Response
```
{
    "data": {
        "checking_account": {
            "balance": 100000,
            "number": "73960914"
        },
        "user": {
            "email": "bar@foo.com",
            "id": "2b9153bd-efc1-4289-af8b-11e6846bcc04",
            "name": "Bar"
        }
    }
}
```

*POST* `/sign_in` - Responsável pela autenticação do usuário, retornar o Authorization Token a ser utilizado nas apis que exijam autenticação:
#### Example
Request
```
{
    "email": "bar@foo.com",
    "password": "somePassword"
}
```
Response
```
{
    "token": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJzdG9uZSIsImV4cCI6MTYwNzg1ODE5NiwiaWF0IjoxNjA1NDM4OTk2LCJpc3MiOiJzdG9uZSIsImp0aSI6IjVhYjI3NzQ3LWVmZjktNDlmMi04Mzc1LTA3ZTNiNmMzNjg5MiIsIm5iZiI6MTYwNTQzODk5NSwic3ViIjoiMmI5MTUzYmQtZWZjMS00Mjg5LWFmOGItMTFlNjg0NmJjYzA0IiwidHlwIjoiYWNjZXNzIn0.KnOAvbdiXE5Hadk24FBzsj4USyr1fzpf69SWZyUqyfQ72fYqS8UDzLaszotgjuLZo0sqKXiNlfiW6S6AGYD7XQ"
}
```
### Transactions
#### Transaction ID
Para toda transaction é necessário enviar um transaction id junto, é uma forma básica de evitar que uma mesma transação seja enviada mais de uma vez.

Para obter um transaction id válido é necessário chamar a seguinte API:

*GET* `/transaction_id` - Retorna um novo transaction id a ser utilizado em uma transação
#### Example
Response
```
{
    "transaction_id": "3ad83f4b-00af-4b01-9158-a0b1039eb440"
}
```

#### Withdrawal
Realiza uma operação de saque na conta do usuário logado.

*POST* `/withdrawal`
- `transaction_id` -> ID da transação, vide seção [Transaction ID](#transaction-id)
- `amount` -> Montante a ser debitado da conta, número inteiro não negativo
#### Example
Request
```
{
    "transaction_id": "3ad83f4b-00af-4b01-9158-a0b1039eb440",
    "amount": 10000
}
```
Response
```
{
    "amount": 10000,
    "description": "Withdrawal from checking account",
    "id": "7a1859d4-9461-4f85-9b5d-9fed5b85b02e",
    "type": "debit"
}
```

#### Transfer
Realiza uma operação de transferência na conta do usuário logado para uma conta de destino. O valor é debitado da conta do usuário logado e creditado na conta destino.

*POST* `/transfer`
- `transaction_id` -> ID da transação, vide seção [Transaction ID](#transaction-id)
- `amount` -> Montante a ser debitado da conta origem e creditado na conta destino, número inteiro não negativo
- `destination_account_number` -> Número da conta de destino a ser creditado
#### Example
Request
```
{
    {
    "transaction_id": "b94fefca-3e3f-4479-a47e-6f37f056abde",
    "amount": 10000,
    "destination_account_number": "73960914"
}
}
```
Response
```
{
    "amount": 10000,
    "description": "Withdrawal from checking account",
    "id": "7a1859d4-9461-4f85-9b5d-9fed5b85b02e",
    "type": "debit"
}
```
