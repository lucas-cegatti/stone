# Stone
Código com a solução para o desafio [API de Banking da Stone](https://gist.github.com/Isabelarrodrigues/15e62f07eebf4e076b93897a64d9c674).

A versão online está disponível neste link [https://stoneapi.gigalixirapp.com/api/v1](https://stoneapi.gigalixirapp.com/api/v1)
## Versions
- Elixir 1.11.2
- OTP 22.3.2

## Docker
O build da imagem docker é feito utilizando o `mix release`, migrations e seeds são rodados automaticamente, há também um arquivo docker-compose que inicia o banco e a aplicação.

### Build
`docker-compose build stone`

ou

`docker build -t stone .`

### Run
`docker-compose up`

ou

```
docker run -e DB_NAME=stone_dev \
-e DB_HOST=db \
-e DB_USER=postgres \
-e DB_PASS=postgres \
-e DATABASE_URL=ecto://postgres:postgres@db/stone_dev \
-e SECRET_KEY_BASE=MBBhVeA0yci+a94dbzKqgog3yjNKVHe63FFPEHmsELr6idwPivSxRNSUIs09B13w \
stone
```
Iniciar via docker requer um database local rodando e que seja acessível pela imagem.
## API
A API utiliza autenticação via JWT token onde deve ser enviado o `Authorization` header nas apis que requerem autenticação.

- [/api/v1/sign_up](#sign-up)
- [/api/v1/sign_in](#sign-in)
- [/api/v1/self](#self)
- [/api/v1/transaction_id](#transaction-id)
- [/api/v1/withdrawal](#withdrawal)
- [/api/v1/transfer](#transfer)
- [/api/v1/reports/day](#reports)
- [/api/v1/reports/month](#reports)
- [/api/v1/reports/year](#reports)
- [/api/v1/reports/total](#reports)

### Sign Up
*POST* `/sign_up` - Responsável pelo cadastro de um novo usuário e também pela criação da conta com o crédito de R$ 1.000,00:
#### Example
Request
```json
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
```json
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
### Sign In
*POST* `/sign_in` - Responsável pela autenticação do usuário, em caso de sucesso retorna o jwt token a ser utilizado nas apis que exijam autenticação:
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

### Self
*Requer token para autenticação*

*GET* `/self` - Retorna os dados do usuário logado.

Response
```json
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

### Transactions
*Requer token para autenticação*
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
    "transaction_id": "b94fefca-3e3f-4479-a47e-6f37f056abde",
    "amount": 10000,
    "destination_account_number": "73960914"
}
```
Response
```
{
    "amount": 10000,
    "description": "Transfered to 73960914",
    "id": "39e1c707-0865-4f28-8aa5-0cbb0f668924",
    "type": "debit"
}
```

#### Códigos de Erro
- T0001 - Transaction id inválido
- T0002 - Amount não inteiro enviado
- T0003 - Amount enviado resultando em saldo negativo
- T0004 - Número de conta invalido
- T0005 - Amount negativo enviado
- T0006 - Tentativa de transferência para mesma conta

##### Exemplo retorno erro
```json
{
    "error": {
        "code": "T0001",
        "message": "Invalid Transaction ID given d8eebd33-dde6-43f6-8213-5469c27ffe1a"
    }
}
```
### Reports
*Requer token para autenticação*

Foram criadas 4 rotas para os relatórios:
- `/day` - Retorna o total agregado + as transações de 1 dia
- `/month` - Retorna o total agregado + as transações dos últimos 30 dias
- `/year` - Retorna o total agregado + as transações dos últimos 365 dias
- `/total` - Retorna o total agregado + todas as transações

Nenhuma das rotas necessita de parâmetros, apenas o Authorization header é necessário.
#### Example
Response
```
{
    "total": "R$1.000,00",
    "total_credits": "R$1.000,00",
    "total_debits": "R$0,00",
    "transactions": [
        {
            "amount": "R$1.000,00",
            "description": "Initial Credit For Opening Account :)",
            "event_date": "14/11/2020 10:36:19",
            "id": "ebfe45b1-150b-47f0-806a-8dc397579d7e",
            "type": "credit"
        }
    ]
}
```
#### Códigos de Erro
- R0001 - Resultado vazio para o período
- R0002 - Número de conta inválido
##### Exemplo retorno erro
```json
{
    "error": {
        "code": "R0001",
        "message": "Empty ledger balance found."
    }
}
```

### Email
Para o email é apenas feito um registro via `Logger.warn()` a geração do conteúdo html é feita através do template Phoenix.