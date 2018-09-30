//
//  Expression.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 28/06/2018.
//

import Foundation

public indirect enum Expression: Node {
    
    case integerLiteral(String)
    case floatLiteral(String)
    case textLiteral(String)
    case templatedText([Expression])
    case booleanLiteral(String)
    case identifier(String)
    case listAccess(String, Expression)
    case listLiteral([Expression])
    case functionCall(String, [Expression])
    case prefix(String, Expression)
    case parentheses(Expression)
    case dot(Expression, Expression)
    case operation(Expression, String, Expression)
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()

        let validValuePrefix: [(key: ValueType, value: [TokenType])] = [
            (.parentheses, [ .parensOpen ]),
            (.prefixOperated, [ .prefixOperator ]),
            (.listLiteral, [ .bracketOpen ]),
            (.functionCall, [ .identifier, .parensOpen ]),
            (.listAccess, [ .identifier, .bracketOpen ]),
            (.identifier, [ .identifier ]),
            (.integerLiteral, [ .decimal ]),
            (.floatLiteral, [ .floatingPoint ]),
            (.textLiteral, [ .textLiteral ]),
            (.booleanLiteral, [ .booleanLiteral ])
        ]
        
        guard let valueType = (validValuePrefix.first { (key, types) -> Bool in
            tokens.hasPrefixTypes(types: types, skipping: [ .newline, .comment ])
        })?.key else {
            throw ZolangError(type: .invalidExpression, file: context.file, line: context.line)
        }
        
        switch valueType {
        case .listAccess:
            let lineCount = tokens.newLineCount(to: tokens.index(ofNextWithTypeIn: [ .bracketOpen ])!)
            guard let range = tokens.rangeOfScope(open: .bracketOpen, close: .bracketClose) else {
    
                throw ZolangError(type: .missingMatchingBracket, file: context.file, line: context.line + lineCount)
            }
            
            if let operatorExpression = try Expression.parseOperator(index: range.upperBound + 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else if let dotExpression = try Expression.parseDotSeparated(index: range.upperBound + 1,
                                                                           tokens: tokens,
                                                                           context: &context) {
                self = dotExpression
            } else {
                guard let identifier = tokens.first(where: { $0.type == .identifier })?.payload else {
                    throw ZolangError(type: .missingIdentifier, file: context.file, line: context.line)
                }

                guard range.count >= 3 else {
                    throw ZolangError(type: .invalidExpression, file: context.file, line: context.line)
                }
                
                var innerTokens = Array(tokens[range.lowerBound+1..<range.upperBound])
            
                let leading = innerTokens.trimLeadingNewlines()
                let trailing = innerTokens.trimTrailingNewlines()
                
                guard innerTokens.isEmpty == false else {
                    throw ZolangError(type: .invalidExpression, file: context.file, line: context.line)
                }
                
                context.line += leading + trailing

                self = .listAccess(identifier, try Expression(tokens: innerTokens, context: &context))
            }
        case .prefixOperated:
            let prefix = tokens.first!.payload!
            guard tokens.count > 1 else {
                throw ZolangError(type: .invalidExpression,
                                  file: context.file,
                                  line: context.line)
            }
            let rest = Array(tokens.suffix(from: 1))
            let expression = try Expression(tokens: rest, context: &context)
            self = .prefix(prefix, expression)
        case .parentheses:
            guard let parensRange = tokens.rangeOfScope(open: .parensOpen, close: .parensClose) else {
                throw ZolangError(type: .missingMatchingParens, file: context.file, line: context.line)
            }
            
            guard parensRange.count > 2 else {
                throw ZolangError(type: .invalidExpression, file: context.file, line: context.line)
            }
            
            if let operatorExpression = try Expression.parseOperator(index: parensRange.upperBound + 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else if let dotExpression = try Expression.parseDotSeparated(index: parensRange.upperBound + 1,
                                                                           tokens: tokens,
                                                                           context: &context) {
                self = dotExpression
            } else {
                let innerTokenRange: CountableRange<Int> = (parensRange.lowerBound + 1)..<parensRange.upperBound
                let innerTokens = Array(tokens[innerTokenRange])
                
                self = .parentheses(try Expression(tokens: innerTokens, context: &context))
            }
        case .functionCall:
            let identifier = tokens.first!.payload!

            let indexOfParens = tokens.index(ofAnyIn: [ .parensOpen ])!
            let numberOfNewlines = tokens.newLineCount(to: indexOfParens)
            guard let parensRange = tokens.rangeOfScope(open: .parensOpen, close: .parensClose),
                parensRange.count >= 2 else {
                throw ZolangError(type: .invalidExpression, file: context.file, line: context.line + numberOfNewlines)
            }
            
            if let operatorExpression = try Expression.parseOperator(index: parensRange.upperBound + 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else if let dotExpression = try Expression.parseDotSeparated(index: parensRange.upperBound + 1,
                                                                            tokens: tokens,
                                                                            context: &context) {
                self = dotExpression
            }  else {
                self = .functionCall(identifier, try .parseExpressionList(tokens: tokens,
                                                                          scopeDef: (.parensOpen, .parensClose),
                                                                          seperators: [ .comma ],
                                                                          context: context))
            }

        case .listLiteral:
            guard let rangeOfBrackets = tokens.rangeOfScope(open: .bracketOpen, close: .bracketClose) else {
                throw ZolangError(type: .missingMatchingBracket, file: context.file, line: context.line)
            }

            if let operatorExpression = try Expression.parseOperator(index: rangeOfBrackets.upperBound + 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else if let dotExpression = try Expression.parseDotSeparated(index: rangeOfBrackets.upperBound + 1,
                                                                           tokens: tokens,
                                                                           context: &context) {
                self = dotExpression
            } else {
                self = .listLiteral(try .parseExpressionList(tokens: tokens,
                                                             scopeDef: (.bracketOpen, .bracketClose),
                                                             seperators: [ .comma ],
                                                             context: context))
            }
        case .identifier:
            if let operatorExpression = try Expression.parseOperator(index: 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else if let dotExpression = try Expression.parseDotSeparated(index: 1,
                                                                           tokens: tokens,
                                                                           context: &context) {
                self = dotExpression
            } else {
                guard tokens.count == 1 else {
                    throw ZolangError(type: .unexpectedToken(tokens[1], nil),
                                      file: context.file,
                                      line: context.line)
                }
                
                self = .identifier(tokens.first!.payload!)
            }
        case .floatLiteral:
            if let operatorExpression = try Expression.parseOperator(index: 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else if let dotExpression = try Expression.parseDotSeparated(index: 1,
                                                                            tokens: tokens,
                                                                            context: &context) {
                self = dotExpression
            } else {
                guard tokens.count == 1 else {
                    throw ZolangError(type: .unexpectedToken(tokens[1], nil),
                                      file: context.file,
                                      line: context.line)
                }

                self = .floatLiteral(tokens.first!.payload!)
            }
        case .integerLiteral:
            if let operatorExpression = try Expression.parseOperator(index: 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else if let dotExpression = try Expression.parseDotSeparated(index: 1,
                                                                           tokens: tokens,
                                                                           context: &context) {
                self = dotExpression
            } else {
                guard tokens.count == 1 else {
                    throw ZolangError(type: .unexpectedToken(tokens[1], nil),
                                      file: context.file,
                                      line: context.line)
                }
                
                self = .integerLiteral(tokens.first!.payload!)
            }
        case .textLiteral:
            if let operatorExpression = try Expression.parseOperator(index: 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else if let dotExpression = try Expression.parseDotSeparated(index: 1,
                                                                           tokens: tokens,
                                                                           context: &context) {
                self = dotExpression
            } else {
                guard tokens.count == 1 else {
                    throw ZolangError(type: .unexpectedToken(tokens[1], nil),
                                      file: context.file,
                                      line: context.line)
                }
                
                let str = tokens.first!.payload!
                var templateRanges: [ClosedRange<Int>] = []
                var i = 0
                while i < str.count {
                    let working = String(str.suffix(from: str.index(str.startIndex, offsetBy: i)))
                    if working.zo.getPrefix(regex: "[^\\\\]\\$\\{") != nil,
                        let range = str.zo.getScope(open: "{", close: "}", start: i) {
                        i = range.upperBound + 1
                        templateRanges.append(range)
                    } else {
                        i += 1
                    }
                }
                
                guard templateRanges.isEmpty == false else {
                    self = .textLiteral(str)
                    return
                }
                
                var expressions: [Expression] = []
                var lastEndIndex: String.Index = str.startIndex
                try templateRanges.forEach { range in
                    
                    guard range.count > 2 else {
                        throw ZolangError.ErrorType.unknown
                    }

                    let rangeLower = str.index(str.startIndex, offsetBy: range.lowerBound)
                    let rangeUpper = str.index(str.startIndex, offsetBy: range.upperBound)
                    
                    if lastEndIndex != rangeLower {
                        let startOfTemplate = str.index(str.startIndex, offsetBy: range.lowerBound - 1)
                        let range = lastEndIndex..<startOfTemplate
                        
                        
                        expressions.append(.textLiteral(String(str[range])))
                    }

                    let lower = str.index(str.startIndex, offsetBy: range.lowerBound + 1)
                    let upper = str.index(str.startIndex, offsetBy: range.upperBound - 1)
                    
                    let expressionRange = lower...upper
                    let expression = try Expression(tokens: String(str[expressionRange]).zo.tokenize(),
                                                    context: &context)
                    expressions.append(expression)
                    
                    lastEndIndex = str.index(rangeUpper, offsetBy: 1)
                }

                self = .templatedText(expressions)
            }
        case .booleanLiteral:
            if let operatorExpression = try Expression.parseOperator(index: 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else if let dotExpression = try Expression.parseDotSeparated(index: 1,
                                                                           tokens: tokens,
                                                                           context: &context) {
                self = dotExpression
            } else {
                guard tokens.count == 1 else {
                    throw ZolangError(type: .unexpectedToken(tokens[1], nil),
                                      file: context.file,
                                      line: context.line)
                }
                
                self = .booleanLiteral(tokens.first!.payload!)
            }
        }
    }
    
    static func parseOperator(index: Int, tokens: [Token], context: inout ParserContext) throws -> Expression? {
        var tokens = tokens

        guard index < tokens.count,
            let nextIndex = tokens.index(ofFirstThatIsNot: .newline, startingAt: index),
            nextIndex != tokens.count - 1,
            tokens[nextIndex].type == .operator else {
            return nil
        }
        
        let newlinesToAdd = tokens.trimNewlines(to: nextIndex)
        let operatorIndex = nextIndex - newlinesToAdd

        let leftTokens = Array(tokens[..<operatorIndex])
        let rightTokens = Array(tokens[operatorIndex+1..<tokens.count])
        
        var leftExpressionTokens = leftTokens
        let trailing = leftExpressionTokens.trimTrailingNewlines()

        let firstExpression = try Expression(tokens: leftExpressionTokens, context: &context)
        
        context.line += newlinesToAdd + trailing
        
        let secondExpression = try Expression(tokens: rightTokens, context: &context)
        
        return .operation(firstExpression,
                          tokens[operatorIndex + trailing].payload!,
                          secondExpression)
    }
    
    static func parseDotSeparated(index: Int, tokens: [Token], context: inout ParserContext) throws -> Expression? {
        var tokens = tokens
        
        guard index < tokens.count,
            let nextIndex = tokens.index(ofFirstThatIsNot: .newline, startingAt: index),
            nextIndex != tokens.count - 1,
            tokens[nextIndex].type == .dot else {
                return nil
        }
        
        let newlinesToAdd = tokens.trimNewlines(to: nextIndex)
        let operatorIndex = nextIndex - newlinesToAdd
        
        let leftTokens = Array(tokens[..<operatorIndex])
        let rightTokens = Array(tokens[operatorIndex+1..<tokens.count])
        
        var leftExpressionTokens = leftTokens
        let trailing = leftExpressionTokens.trimTrailingNewlines()
        
        let firstExpression = try Expression(tokens: leftExpressionTokens, context: &context)
        
        context.line += newlinesToAdd + trailing
        
        let secondExpression = try Expression(tokens: rightTokens, context: &context)
        guard secondExpression.canDotSyntax() == false else {
            throw ZolangError(type: .invalidExpression,
                              file: context.file,
                              line: context.line)
        }
        return .dot(firstExpression,
                    secondExpression)
    }
    
    public func getContext(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> [String : Any] {
        switch self {
        case .booleanLiteral(let str):
            return [
                "expressionType": "booleanLiteral",
                "value": str
            ]
        case .prefix(let prefix, let expression):
            return [
                "expressionType": "prefix",
                "prefix": prefix,
                "expression": try expression.compile(buildSetting: buildSetting)
            ]
        case .floatLiteral(let str):
            return [
                "expressionType": "floatLiteral",
                "value": str
            ]
        case .integerLiteral(let str):
            return [
                "expressionType": "integerLiteral",
                "value": str
            ]
        case .textLiteral(let str):
            return [
                "expressionType": "textLiteral",
                "value": str
            ]
        case .templatedText(let expressions):
            let expressionStrings = try expressions
                .map { expr in
                    try expr.compile(buildSetting: buildSetting,
                                     fileManager: fm)
                }
            return [
                "expressionType": "templatedText",
                "expressions": expressionStrings
            ]
        case .identifier(let str):
            return [
                "expressionType": "identifier",
                "value": str
            ]
        case .functionCall(let name, let expressions):
            return [
                "expressionType": "functionCall",
                "name": name,
                "expressions": try expressions.map { try $0.compile(buildSetting: buildSetting, fileManager: fm) }
            ]
        case .listAccess(let identifier, let expression):
            return [
                "expressionType": "listAccess",
                "identifier": identifier,
                "expression": try expression.compile(buildSetting: buildSetting, fileManager: fm)
            ]
        case .listLiteral(let expressions):
            return [
                "expressionType": "listLiteral",
                "expressions": try expressions.map { try $0.compile(buildSetting: buildSetting, fileManager: fm) }
            ]
        case .parentheses(let expression):
            return [
                "expressionType": "parentheses",
                "expression": try expression.compile(buildSetting: buildSetting, fileManager: fm)
            ]
        case .operation(let lExpr, let op, let rExpr):
            return [
                "expressionType": "operation",
                "leftExpression": try lExpr.compile(buildSetting: buildSetting, fileManager: fm),
                "rightExpression": try rExpr.compile(buildSetting: buildSetting, fileManager: fm),
                "operator": op
            ]
        case .dot(let lExpr, let rExpr):
            return [
                "expressionType": "dot",
                "leftExpression": try lExpr.compile(buildSetting: buildSetting, fileManager: fm),
                "rightExpression": try rExpr.compile(buildSetting: buildSetting, fileManager: fm)
            ]
        }
    }
    
    func canDotSyntax() -> Bool {
        switch self {
        case .booleanLiteral(_), .floatLiteral(_), .listLiteral(_), .integerLiteral(_), .operation(_, _, _), .parentheses(_), .templatedText(_), .textLiteral(_), .prefix(_, _):
            return false
        case .dot(_, _), .functionCall(_, _), .identifier(_), .listAccess(_, _):
            return true
        }
    }
    
    public static func ~= (left: Expression, right: Expression) -> Bool {
        switch (left, right) {
        case (.textLiteral(let l), .textLiteral(let r)),
             (.integerLiteral(let l), .integerLiteral(let r)),
             (.floatLiteral(let l), .floatLiteral(let r)),
             (.booleanLiteral(let l), .booleanLiteral(let r)),
             (.identifier(let l), .identifier(let r)):
            return l == r
        case (.dot(let lExpr1, let lExpr2), .dot(let rExpr1, let rExpr2)):
            return lExpr1 ~= rExpr1 && lExpr2 ~= rExpr2
        case (.operation(let lExpr1, let lOp, let lExpr2), .operation(let rExpr1, let rOp, let rExpr2)):
            return lOp == rOp && lExpr1 ~= rExpr1 && lExpr2 ~= rExpr2
        case (.listAccess(let sL, let exprL), .listAccess(let sR, let exprR)),
             (.prefix(let sL, let exprL), .prefix(let sR, let exprR)):
            return sL == sR && exprL ~= exprR
        case (.templatedText(let lExprs), .templatedText(let rExprs)),
             (.listLiteral(let lExprs), .listLiteral(let rExprs)):
            guard lExprs.count == rExprs.count else { return false }
            var i = 0
            while i < lExprs.count {
                defer { i += 1 }
                guard lExprs[i] ~= rExprs[i] else {
                    return false
                }
            }
            return true
        case (.parentheses(let lExpr), .parentheses(let rExpr)):
            return lExpr ~= rExpr
        case (.functionCall(let lName, let lExprs), .functionCall(let rName, let rExprs)):
            guard lName == rName,
                lExprs.count == rExprs.count else { return false }
            var i = 0
            while i < lExprs.count {
                defer { i += 1 }
                guard lExprs[i] ~= rExprs[i] else {
                    return false
                }
            }
            return true
        }
    }
}

extension Expression {
    private enum ValueType: String {
        case functionCall
        case prefixOperated
        case parentheses
        case listAccess
        case listLiteral
        case identifier
        case integerLiteral
        case floatLiteral
        case textLiteral
        case booleanLiteral
    }
}

extension Array where Element == Expression {
    static func parseExpressionList(tokens: [Token], scopeDef: (open: Token, close: Token), seperators: [TokenType], context: ParserContext) throws -> [Expression] {
        guard let indexOfOpen = tokens.index(ofAnyIn: [ scopeDef.open.type ]) else {
            throw ZolangError(type: .missingToken(String(describing: scopeDef.open.payload)),
                                                  file: context.file,
                                                  line: context.line)
        }

        let numberOfNewlines = tokens.newLineCount(to: indexOfOpen)
        guard let scopeRange = tokens.rangeOfScope(open: scopeDef.open, close: scopeDef.close),
            scopeRange.count >= 2 else {
                throw ZolangError(type: .invalidExpression,
                                  file: context.file,
                                  line: context.line + numberOfNewlines)
        }
        
        guard scopeRange.count > 2 else { return [] }
        
        let startOfList = scopeRange.lowerBound + 1
        
        guard let commaIndices = tokens.indices(of: [ .comma ],
                                                outsideOf: [ (.parensOpen, .parensClose), (.bracketOpen, .bracketClose) ],
                                                startingAt: startOfList),
            commaIndices.isEmpty == false else {

            var context = context
            let innerTokenRange = (scopeRange.lowerBound + 1)...(scopeRange.upperBound - 1)
            let innerTokens = [Token](tokens[innerTokenRange])

            let lines = tokens.newLineCount(to: innerTokenRange.lowerBound)
            context.line += lines
            var expressions: [Expression] = []
            if let expression = (try? Expression(tokens: innerTokens, context: &context)) {
                expressions.append(expression)
            }
            
            return expressions
        }
        
        
        var start: Int = startOfList
        
        let oldLineCount = context.line
        
        let parseExpressionForRange: (CountableRange<Int>) throws -> Expression = { [unowned context] range in
            var context = context
            
            let newlineCount = tokens.newLineCount(to: range.lowerBound)

            let expressionTokens = [Token](tokens[range])
            
            context.line = oldLineCount + newlineCount
            let expression = try Expression(tokens: expressionTokens, context: &context)
            return expression
        }
        
        var expressions = try commaIndices
            .map { commaIndex throws -> Expression in
                let range = start..<commaIndex
                start = commaIndex + 1
                
                return try parseExpressionForRange(range)
        }
        
        if let expression = (try? parseExpressionForRange(start..<scopeRange.upperBound)) {
            expressions.append(expression)
        }
        
        return expressions
    }
}
