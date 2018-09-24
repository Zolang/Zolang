

![alt text](https://github.com/Zolang/Zolang/blob/master/Images/zolang-banner.png "Zolang logo")
# Zolang

## What is it?

Zolang is a programming language theoretically transpilable to virtually any other programming language.

Zolang does this by offloading code generation to its users through [Stencil (template language)](https://stencil.fuller.li/en/latest/).

> Zolang is a lightweight front end for virtually any general purpose programming language.

Theoretically though, these specification files could make Zolang output any kind of text. Making the language a very useful code generation tool.

## Name
I'm a Star Wars fan and In the Star Wars world Zolan is the home planet of a species called clawdites, who are known for their ability to transform their appearance to be the one of virtually any other creature.

As the language aims to be transpilable to virtually any other programming language the clawdites came quickly to mind. Sadly the species doesn't have a catchy name, so I found myself falling back to their planet Zolan. And since this is a language and lang is often used as an abbreviation for language the "g" was soon to follow.

## Documentation

### Installation

### Getting Started

In your project, create a zolang folder 

```
zolang init
```

This will create a zolang.json file that will be used to specify build settings for your Zolang code. For example a typical Zolang project compiling to Swift would look something like this:

```JSON
{
  "buildSettings": [
    {
      "sourcePath": "./src",
      "stencilPath": "./templates/swift",
      "buildPath": "./build/swift",
      "separators": {
        "CodeBlock": "\n"
      }
    }
  ]
}
```

Notice the `./templates/swift`. This is the location of the `.stencil` files that customize the actual code generation process. The Zolang organization has [a repo of supported languages](https://github.com/Zolang/ZolangTemplates)

#### Defining Models
We could create a file `.build/swift/Person.zolang`

```zolang
describe Person {
	name as text
	street as text
	number as number
	friendNames as list of text

	address return text from () {
		let addr as text be "${street} ${number}"
		print("Fetching address ${addr}")
		return addr
	}

	speak return from (message as text) {
		print("${name} says ${message}")
	}
}

```

#### Variable Declaration

```zolang
let person as Person be Person("John Doe", "John's Street", 8)
```

#### Mutation

```zolang
make person.name be "Jane Doe"
```

#### Invoking Functions

```zolang
person.speak("My address is ${person.address()}")
```

#### Building

```
zolang build --swift
```
Now `./build/swift/Person.zolang` would contain the following:

```swift
class Person: Codable {
	var name: String
	var street: String
	var number: Double
	var friendNames: [String]

	init(_ name: String, _ street: String, number: Double) {
		self.name = name
		self.street = street
		self.number = number
	}

	func address() -> String {
		let addr = "\(street) \(number)"
		print("fetching address \(addr)")
		return addr
	}

	func speak(message: String) {
		print("\(name)" + "says" + "\(message)")
	}
}

var person = Person("John Doe", "John's Street", 8)

person.name = "Jane Doe"

person.speak("My address is " + "\(person.address())")
```
