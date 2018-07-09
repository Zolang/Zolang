# Zolang

## What is it?

The language is an attempt to solve a classic problem in implementations of cross platform software. When these applications need to use platform specific APIs they are often forced to rewrite a lot of boilerplate code for each platform.

Zolang aims to minimise this boilerplate code by following the "write once run everywhere" paradigm and be transpilable to virtually any general purpose programming language. Zolang does this by offloading code generation to its users, who will be able to request features on demand by implementing transpiler specification files.

The above claims result in the definition:

> Zolang is a limited, highly readable, typesafe frontend for virtually any general purpose programming language.

## Name
I'm a Star Wars fan and In the Star Wars world Zolan is the home planet of a species called clawdites, who are known for their ability to transform their appearance to be the one of virtually any other creature.

As the language aims to be transpilable to virtually any other programming language the clawdites came quickly to mind. Sadly the species doesn't have a catchy name, so I found myself falling back to their planet Zolan. And since this is a language and lang is often used as an abbreviation for language the "g" was soon to follow.

## Designing Zolang

It's now important to mention that Zolang is not a general purpose programming
language. Because of its niche purpose there are a few characteristics that
must be in place:

**1) Zolang needs to be unique**

Zolang's transpilability brings many limitations. Therefor it's important for Zolang to be unique. Programming in Zolang must not feel exactly like programming in any other language, because it would only make it seem incomplete.

**2) Zolang needs to be accessible to non-programmers**

Because Zolang aims to be a tool for describing applications' model layer, it's
important for it to be able to contribute to lower costs of writing software.

An application's model layer does not usually require complex design patterns,
thus it should not need software specialists to implement. Zolang aims to make model descriptions and simple data formatting look familiar to anyone who knows the basics of the english language.

### Example

To illustrate this I would like to compare Zolang and my favorite general purpose programming language, Swift. A description of
a "Person" could be something like:

```
struct Person {
	let name: String
	let street: String
	let number: Int

	func address() -> String {
		let addr = "\(street) \(number)"
		print("fetching address \(addr)")
		return addr
	}

	func speak(message: String) {
		print("\(name) says \(message")
	}
}
```

For the average programmer or mathematician this is very readable, but for the average corporate employee it raises a few questions. What is a struct? What is a String? What does : mean? What does func mean? What does -> mean?

Zolang tries to tackle some of these problems by embedding english more heavily in its syntax. This has been successfully done by several languages, most notably SQL.

E.g. Zolang replaces `String` with `text` and tries to avoid the extensive use of virtually meaningless tokens such as `:` and `->`.  


```
describe Person {
	name as text
	street as text
	number as integer

	address return text from () {
		let addr be "${street} ${number}"
		print("Fetching address ${addr}")
		return addr
	}

	speak return from (message as text) {
		print("${name} says ${message}")
	}
}
```

Alternatively address could be defined at init

```
describe Person {
	name as text
	street as text
	number as integer
	address as text from ()
}
```

This version of Person would now be initialized:

```
let person be Person(name: "John Doe",
					 street: "John's Street",
					 number: 8,
					 address: text from () {
						return "John's Street 8"
					 })
```

Of course the problem with this is that now if we mutate street or number, the address will not update automatically. We can manually update the person's by using `make`.

```
make person.address return text from () {
	return "Jane Doe"
}
```

Using a similar notation we could also alter the person's name.

```
make person.name be "Jane Doe"
```

