# Kora

### What is it?
Kora is a programmable, real-time database that allows you to store and sync data across all clients both online and offline. Clients (iOS, Android, Web, Servers) can directly connect to Kora and securely read and write data from the system.  Data can also be persisted locally so it is available even if the device goes offline and once it regains connection, Kora will synchronize the missing changes and resolve conflicts automatically.

The major difference between Kora and other systems like Firebase or CouchDB is its **Interceptor Framework**.  This framework provides a way to extend the database by adding hooks that take care of typical API challenges like validating/authenticating input, denormalizing data, and triggering events like Push Notifications or mirroring data into other sources.  This allows for a generic backend while still preserving the ability to keep shared logic on the server instead of duplicating it on the clients.  Since this framework is low-level it can be extended by building a rules engine on top that allows for permissions or denormalization rules to be specified using markup instead of code.

### Data Model
All data in Kora is stored as one huge tree.  It can be thought of as one big object.  Fields can be merged in or deleted and clients can subscribe to sections of the tree and will be notified of any changes underneath them.  Subscriptions can also be stored in the tree for automatic bootstrapping of connections.

#### Example
```javscript
{
	'user:info': {
		'dax': {
			name: 'Dax',
			company: 'ironbay',
		},
		'yousef': {
			name: 'Yousef',
			company: 'ironbay',
		}
	},
	'company:info': {
		'ironbay': {
			name: 'Ironbay',
			city: 'New York',
		}
	},
	'company:employees': {
		'ironbay': {
			'dax': 1493337757300,
			'yousef': 1493337757300,
		}
	}
}
```

As you can see Kora encourages proper NoSQL data modeling through denormalization.  That means data is written in multiple ways for all the ways it needs to be queried to avoid costly query scans. If we want to find all the employees of company `ironbay` we maintain a list of that result instead of scanning `user:info` and filtering.  While this may seem tedious at first, the *Interceptor Framework* greatly reduces the boilerplate needed to build well denormalized data models.

Kora also supports multiple storage modes and can store data in Cassandra, Postgres, or MySQL.

### Setup
Kora is written in Elixir and built on top of Erlang OTP to provide a fault tolerant distributed system that doesn't lose data.  You can read more about [why erlang matters here](https://sameroom.io/blog/why-erlang-matters/).  This means today we support extended Kora through Interceptors written in Elixir, however there are plans to support other languages.  That said Elixir is an awesome language with a lot of great ideas that is worth learning.

Kora is provided as a library that you can add to your elixir project like any other library.

```
{:kora, github: "ironbay/kora"}
```

### Configuration

TODO
