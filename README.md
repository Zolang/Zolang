

![alt text](https://github.com/Zolang/Zolang/blob/master/Images/zolang-banner.png "Zolang logo")
# Zolang

## What is it?

Zolang is a programming language theoretically transpilable to virtually any other programming language.

Zolang does this by offloading code generation to its users through [Stencil (template language)](https://stencil.fuller.li/en/latest/) specification files.

> Zolang is a lightweight frontend for virtually any general purpose programming language.

Theoretically though, these (`.stencil`) specification files could make Zolang output any kind of text. Making the language a very useful code generation tool.

## Why Zolang?

Zolang doesn't try to be a general purpose programming language, it is limited in features and is yet to have a standard library, so why use Zolang instead of other programming languages?

### The Story Behind Zolang

The idea for Zolang came from within a fast moving startup. It was moving fast in the sense that the tech stack was rapidly changing every now and then, the product had projects in 4 languages, Swift, TypeScript, JavaScript and Ruby. All of which had duplications in definitions of models.

So every time the tech stack changed drastically, changes had to be made in many of the (if not all four) implementations. So we wanted a language where we could write the model layer of our application with a single source of truth, generating code for all of our programming languages.

## Name

I'm a Star Wars fan and in the Star Wars world Zolan is the home planet of a species called clawdites, who are known for their ability to transform their appearance to look like virtually any other creature.

As the language aims to be transpilable to virtually any other programming language the clawdites came quickly to mind. Sadly the species doesn't have a catchy name, so I found myself falling back to their planet Zolan. And since this is a language and lang is often used as an abbreviation for language the "g" was soon to follow.

## Roadmap / Upcoming Features

- Access Levels
- Comments
- Default Values
- Type checking
- For loop
- Hot reload (compilation)
- Function mutation

## Documentation

### Installation

#### Download Release
See [releases](https://github.com/Zolang/Zolang/releases)

#### Build From Source

```
g clone https://github.com/Zolang/Zolang
cd Zolang
swift build -c release -Xswiftc -static-stdlib
cd .build/release
cp -f Zolang /usr/local/bin/zolang
```

### Getting Started

#### Setting up development environment

Zolang is best with Visual Studio Code using the [zolang-ide](https://marketplace.visualstudio.com/items?itemName=valdirunars.zolang-ide) extension

#### Initializing Project

If you don't have an existing project start by creating a project folder and navigate to it

```
mkdir  MyZolangProject
cd MyZolangProject
```

Then initialize the project

```
zolang init
```

This will create a zolang.json file that will be used to specify build settings for your Zolang and setup the project's file structure.

### Example

#### The Config File

A typical zolang.json project compiling to Swift would look something like this:

```JSON
{
  "buildSettings": [
    {
      "sourcePath": "./zolang/src",
      "stencilPath": "./zolang/templates/swift",
      "buildPath": "./zolang/build/swift",
			"fileExtension": "swift",
      "separators": {
        "CodeBlock": "\n"
      }
    }
  ]
}
```

Notice the `./templates/swift`. This is the location of the `.stencil` files that customize the actual code generation process. The Zolang organization has [a repo of supported languages](https://github.com/Zolang/ZolangTemplates).

`./zolang/src` is where all the Zolang code is stored.

> 😇 P.S. It only took around 30 minutes to add the templates needed to be able to compile Zolang to the Swift (programming language)! So you shouldn't restrain yourself from using Zolang if your favorite language is not yet supported. Just add it and continue hacking.

#### Defining Models
We could create a file `./zolang/src/Person.zolang`

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
let person as Person be Person("John Doe", "John's Street", 8, [ "Todd" ])
```

#### Mutation

```zolang
make person.name be "Jane Doe"
```

#### Invoking Functions

```zolang
person.speak("My address is ${person.address()}")
```

#### Arithmetic

Lets say we wanted to print something like `1 + 2 + (3 * 4) / 5`

In Zolang this would be written:

```zolang
print("${1 plus 2 plus (3 times 4) over 5}")
```

#### Looping through Lists

```zolang
let i as number be 1

while (i < person.friendNames.count) {
	print(person.friendNames[i])
	make i be i plus 1
}
```

#### Building

```
zolang build
```

Now `./zolang/build/swift/Person.swift` would now contain the following:

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
		print("\(name)" + " says " + "\(message)")
	}
}

var person = Person("John Doe", "John's Street", 8, [ "Todd" ])

person.name = "Jane Doe"

person.speak("My address is " + "\(person.address())")

print("\(1 + 2 + (3 * 4) / 5)")

var i: Double = 1

while (i < person.friendNames.count) {
	print(i)
	i = i + 1
}
```

## License

MIT License

Copyright (c) 2018 Thorvaldur Runarsson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
