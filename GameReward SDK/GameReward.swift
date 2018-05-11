//
//  GameReward.swift
//  GameReward SDK
//
//  Created by Kien Vuong on 5/9/18.
//  Copyright © 2018 GameReward. All rights reserved.
//

import UIKit

public class GameReward{
    
    static var appId : String?
    static var secret : String?
    static var apiUrl = "https://gamereward.io/appapi/";
    static var userToken : String?
    init (){
        
    }
    
    public static func Init(appId:String,secret:String)
    {
        self.secret = secret;
        self.appId = appId;
    }
    
    public static var User : GrdUser {
        get {
            return user!
        }
    }
    
    private static var user : GrdUser?
    
    public static func  GetEpochTime() -> Double
    {
        return NSDate().timeIntervalSince1970
    }
    
    private static func GetImageSize( imageData : [UInt8] ,width : inout Int ,height : inout Int ) -> Void
    {
        width = ReadInt(imageData: imageData, offset:  3 + 15);
        height = ReadInt(imageData: imageData,offset: 3 + 15 + 2 + 2);
    }
    
    
    private static func ReadInt(imageData: [UInt8] , offset: Int ) -> Int
    {
        return Int((imageData[offset] << 8) | imageData[offset + 1])
    }
    
    
    private static func GetObjectData(string: String) ->[String: Any]
    {
        var result :[String: Any] = [:]
        if let data = string.data(using: .utf8) {
            do {
                result = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        if (result.isEmpty)
        {
            result = ["error":100,"message":string] as [String : Any];
        }
        return result;
    }
    
    private static func GetApiKey() -> String
    {
        var t : Int = Int(GameReward.GetEpochTime())
        t = t / 15;
        let k : Int = (t % 20)
        let len : Int = Int(secret!.count / 20);
        let startIndex = secret!.index(secret!.startIndex, offsetBy: k*len)
        let endIndex = secret!.index(startIndex, offsetBy: len-1)
        let str : String = String(secret![startIndex...endIndex])
        let str1 = MD5(str+String(t))
        return str1
    }
    
    private static func Post(action : String, params : [String:String], callback: @escaping ([String:Any]) ->()) -> Void
    {
        let url = URL(string: apiUrl+action)
        // post the data
        var request = URLRequest(url:url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var postData = "api_id="+appId!+"&api_key="+GetApiKey();
        if userToken != nil
        {
            postData = postData+"&token="+userToken!
        }
        for (key,value) in params {
            if value != ""{
                postData = postData + "&"+key+"="+value
            }
        }
        request.httpBody = postData.data(using: .utf8)
        
        // execute the datatask and validate the result
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            print(error.debugDescription)
            if error == nil, let userObject = (try? JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]) {
                callback(userObject)
            }
        }
        task.resume()
        
    }
    
    private static func Get(action : String, params : [String:String], callback: @escaping ([String:Any]) ->()) -> Void
    {
        var path :String = "";
        path = "api_id="+appId!+"&api_key="+GetApiKey();
        if userToken != ""
        {
            path = path+"&token="+userToken!
        }
        
        for (key,value) in params {
            path = path + "&"+key+"="+value
        }
        
        if path.count > 0
        {
            let index = path.index(of: "&")
            path = String(path[index!...])
        }
        
        let url = URL(string: apiUrl+action+"/"+path)
        
        var request = URLRequest(url:url!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error == nil, let userObject = (try? JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]) {
                callback(userObject)
            }
        }
        task.resume()
        
    }
    
    /// <summary>
    /// LogOut user from system.
    /// </summary>
    /// <param name="callback"></param>
    public static func LogOut(callback : @escaping (Int,String)->()) -> Void
    {
        Post(action: "logout", params: [:]) { (results) in
            let error : Int = results["error"] as! Int
            let message : String = results["message"] as! String
            self.user = nil
            self.userToken = nil
            callback(error,message)
        }
    }
    
    
    /// <summary>
    /// This method use to reset password for user. System will send an email change password for user
    /// </summary>
    /// <param name="username">Username user use to login</param>
    /// <param name="password">Password user use to login</param>
    /// <param name="callback">Call when completed.</param>
    public static func ResetPassword(usernameOrEmail : String , callback :@escaping (Int,String,[String:Any])->()) -> Void
    {
        var pars : [String:String]  = [:]
        pars["email"] = usernameOrEmail
        Post(action: "requestresetpassword", params: pars)  { (results) in
            let error : Int = results["error"] as! Int
            let message : String = results["message"] as! String
            callback(error,message,[:])
        }
        
    }
    /// <summary>
    /// This function use to register a new user
    /// </summary>
    /// <param name="username">Username use to login</param>
    /// <param name="password">Password of the account</param>
    /// <param name="email">Email use for reseting password or receiving the message from app.</param>
    /// <param name="userdata">Any data in string</param>
    /// <param name="callback">Call when finish.</param>
    public static func Register(username: String , password: String , email: String , userdata: String , callback :@escaping (Int,String,[String:Any])->()) -> Void
    {
        var pars : [String:String]  = [:]
        pars["username"] = username
        pars["password"] = MD5(password)
        pars["email"] = email
        pars["userdata"] = userdata
        
        Post(action: "createaccount", params: pars){ (results) in
            let error : Int = results["error"] as! Int
            let message : String = results["message"] as! String
            callback(error,message,[:])
        }
    }
    
    /// <summary>
    /// This method use for user login to system. Server response the result is success or failed.
    /// </summary>
    /// <param name="username">Username user use to login</param>
    /// <param name="password">Password user use to login</param>
    /// <param name="callback">Call when completed.</param>
    public static func Login(username : String , password : String ,otp : String , callback :@escaping (Int,String,[String:Any])->()) -> Void
    {
        var pars : [String:String]  = [:]
        pars["username"] = username
        pars["password"] = MD5(password)
        pars["otp"] = otp
        
        Post(action: "login", params: pars){ (results) in
            let error : Int = results["error"] as! Int
            var message : String = ""
            var args : [String:Any] = [:]
            if error==0
            {
                let user : GrdUser = GrdUser()
                user.username = username;
                user.address = results["address"] as! String
                user.email = results["email"] as! String
                user.balance = Decimal(string: results["balance"] as! String)!
                user.otp = (results["otpoptions"] as! Int) != 0
                userToken = results["token"] as? String
                message = "Login successfully"
                args["token"] = userToken
                self.user = user;
            }else
            {
                message = results["message"] as! String
            }
            callback(error,message,args)
        }
    }
    //    /// <summary>
    //    /// Get the qrcode gamereward wallet address
    //    /// </summary>
    //    /// <param name="address">Address of the wallet to encode</param>
    //    /// <param name="callback">Call when server response the QR code</param>
    //    public static func GetAddressQRCode(address : String ,  callback :@escaping (Int,String,UIImage) ->()) -> Void
    //    {
    //        GetQRCode(text: "gamereward:" + address){ (error,message, image) in
    //            callback(error,message,image)
    //        }
    //    }
    //    /// <summary>
    //    /// Get the qrcode from text
    //    /// </summary>
    //    /// <param name="text">The text to encode to QR code</param>
    //    /// <param name="callback">Call when server response QR code.</param>
    //    public static func GetQRCode(text : String , callback :@escaping (Int,String,UIImage) ->()) -> Void
    //    {
    //        var pars : [String:String] = [:]
    //        pars["text"] = text
    //        pars["type"] = "1"
    //
    //        Post(action: "qrcode", params: pars){ (results) in
    //            var texture: UIImage?
    //            var error : Int = results["error"] as! Int
    //            var message : String = ""
    //            var res : [String:Any] = [:]
    //            if error == 0
    //            {
    //                var qrcode : String = results["qrcode"] as! String
    //                if qrcode.count > 0
    //                {
    //                    let index = qrcode.index(qrcode.startIndex, offsetBy: String("data:image/image/png;base64").count )
    //                    qrcode = String(qrcode[index...])
    //                    texture = GetImage(responseText: qrcode)
    //                }else{
    //                    error = 1
    //                    res["message"] = "Cannot generate QrCode"
    //                }
    //            }else{
    //                message = results["message"] as! String
    //            }
    //            callback(error,message,texture!)
    //        }
    //    }
    
    
    public static func GetAddressQrCode(address: String) -> UIImage?
    {
        let addressFormated : String = "gamereward:"+address
        return GetImage(responseText:addressFormated)
    }
    
    private static func GetImage(responseText : String) -> UIImage?
    {
        let data = responseText.data(using: String.Encoding.ascii, allowLossyConversion: false)
        if let filter = CIFilter(name: "CIQRCodeGenerator"){
            filter.setValue(data, forKey: "inputMessage")
            if let output = filter.outputImage{
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    /// <summary>
    /// Call the server script to do logic game on server
    /// </summary>
    /// <param name="scriptName">The name of the script defined on server</param>
    /// <param name="functionName">The name of function you want to call. If the script have return statement in global scope, the functionName can be empty</param>
    /// <param name="parameters">The parameters to pass to the function</param>
    /// <param name="callback">Call when server response result.</param>
    public static func CallServerScript(scriptName : String , functionName : String , parameters : [Any] ,  callback :@escaping (Int,String,[Any])->()) -> Void
    {
        var pars : [String:String] = [:]
        var error : Int = 1
        var message : String = ""
        var res : [Any] = []
        do{
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions.prettyPrinted)
            let values = String(data:jsonData,encoding: String.Encoding.ascii)
            pars["vars"] = values
            pars["fn"] = functionName
            pars["script"] = scriptName
            Post(action: "callserverscript", params: pars){ (results) in
                error = results["error"] as! Int
                message = ""
                if error != 0
                {
                    message = results["message"] as! String
                }else
                {
                    error = 0
                    res = results["result"] as! [Any]
                }
                callback(error,message,res)
            }
        }catch{
            callback(10,"unknown error",[])
        }
        
    }
    
    
    /* private static func FormatNumber(number : Decimal ) -> String
     {
     var array : [Character]  = Array(number.description)
     var isDecimal : Bool = false;
     for (int i = array.Length - 1; i > 0; i--)
     {
     if (!isDecimal)
     {
     if (!char.IsDigit(array[i]))
     {
     array[i] = '.';
     isDecimal = true;
     }
     }
     else
     {
     if (!char.IsDigit(array[i]))
     {
     array[i] = ' ';
     isDecimal = true;
     }
     }
     }
     string result = new string(array);
     result = result.Replace(" ", "");
     return result;
     }*/
    
    /// <summary>
    /// Get the newest user balance from server update to user object.
    /// </summary>
    /// <param name="callback"></param>
    public static func UpdateBalance(callback :@escaping (Int,String,[String:Any])->()) -> Void
    {
        Get(action: "accountbalance", params: [:]){ (results) in
            let error : Int = results["error"] as! Int
            var args : [String:Any] = [:]
            if error == 0
            {
                if results["balance"] as! String != ""
                {
                    User.balance = results["balance"] as! Decimal
                    args["balance"] = User.balance
                    callback(error,"",args)
                }else{
                    args["message"] = "Cannot get balance!"
                    callback(1,"Cannot get balance",args)
                }
            }else{
                callback(error,results["message"] as! String,args)
            }
        }
    }
    /// <summary>
    /// Transfer user money to another wallet
    /// </summary>
    /// <param name="toAddress">Address of the wallet to transfer to</param>
    /// <param name="money">The amount of money to tranfer</param>
    /// <param name="callback">Call when the transfer finished!</param>
    public static func Transfer(toAddress : String , money : Decimal , otp : String ,callback :@escaping (Int,String,[String:Any])->()) -> Void
    {
        var pars : [String:String] = [:]
        pars["to"] = toAddress
        pars["value"] = money.description
        pars["otp"] = otp
        
        Post(action: "transfer", params: pars){ (results) in
            let error : Int = results["error"] as! Int
            let message : String = results["message"] as! String
            var args : [String:Any] = [:]
            if error == 0{
                if results["balance"] as! String != ""
                {
                    User.balance = results["balance"] as! Decimal
                }else{
                    User.balance = User.balance - money;
                }
                args["balance"] = User.balance;
            }
            callback(error,message,args)
        }
        
    }
    /// <summary>
    /// Use when user want to turn on the 2 steps verification.
    /// </summary>
    /// <param name="callback">Call when the request is completed and return the result</param>
    public static func RequestEnableOtp(callback :@escaping (Int,String,[String:Any])->()) -> Void
    {
        Post(action: "requestotp", params: [:]){(results) in
            let error : Int = results["error"] as! Int
            let message : String = results["message"] as! String
            var args : [String:Any] = [:]
            if error == 0
            {
                var qrcode : String = results["qrcode"] as! String
                var texture : UIImage?
                if qrcode.count > 0
                {
                    let index = qrcode.index(qrcode.startIndex, offsetBy: String("data:image/image/png;base64").count )
                    qrcode = String(qrcode[index...])
                    texture = GetImage(responseText: qrcode)
                    args["image"] = texture
                    args["serect"] = results["secret"] as! String
                }
            }
            callback(error,message,args)
        }
    }
    /// <summary>
    /// Allow user enable or disable the 2 steps verification security options
    /// </summary>
    /// <param name="otp">The string 6 digits otp code generate by google authentication app</param>
    /// <param name="enabled">True if enable otp, false if disable</param>
    /// <param name="callback">Call when finished the request</param>
    public static func EnableOtp(otp: String , enabled: Bool, callback :@escaping (Int,String)->()) -> Void
    {
        var pars : [String:String] = [:]
        pars["otp"] = otp
        pars["otpoptions"] = enabled ? "1" : "0"
        
        Post(action: "enableotp", params: pars){ (results) in
            let error : Int = results["error"] as! Int
            let message : String = results["message"] as! String
            if error == 0
            {
                User.otp = enabled
            }
            callback(error,message)
        }
    }
    /// <summary>
    /// Get the leaderboard list by score type
    /// </summary>
    /// <param name="scoreType">The score type want to get leaderboard</param>
    /// <param name="start">Start from rank</param>
    /// <param name="count">Number of item return</param>
    /// <param name="callBack">Call when finished the action</param>
    public static func GetLeaderBoard(scoreType : String ,start : Int ,count: Int ,callback :@escaping (Int,String,[String:Any])->()) -> Void
    {
        var pars : [String:String] = [:]
        pars["scoretype"] = scoreType
        pars["start"] = String(start)
        pars["count"] = String(count)
        
        Post(action: "getleaderboard", params: pars){ (results) in
            let error : Int = results["error"] as! Int
            let message : String = results["message"] as! String
            var args : [String:Any] = [:]
            var leaderBoard : [LeaderBoardItem] = []
            if error == 0
            {
                leaderBoard = results["leaderboard"] as! [LeaderBoardItem]
                args["leaderboard"] = leaderBoard
            }
            callback(error,message,args)
        }
    }
    
    
    public static func GetUserSessionData(store: String, key : String, start : Int, count : Int , callback :@escaping (Int,String,[String:Any])->()) -> Void
    {
        GetUserSessionData(store: store, keys: [key], start: start, count: count){ (error,message,results) in
            callback(error,message,results)
        }
    }
    
    
    public static func GetUserSessionData(store : String ,keys : [String],start : Int ,count : Int ,callback :@escaping (Int,String,[String:Any])->()) -> Void
    {
        var pars : [String:String] = [:]
        pars["store"] = store
        pars["keys"] = keys.joined(separator: ",")
        pars["start"] = String(start)
        pars["count"] = String(count)
        
        Post(action: "getusersessiondata", params: pars){ (results) in
            let error : Int = results["error"] as! Int
            let message : String = results["message"] as! String
            var args : [String:Any] = [:]
            let sessionData = results["data"] as? SessionData
            if sessionData != nil
            {
                args["data"] = sessionData
            }
            callback(error,message,args)
        }
    }
    
    
    public static func GetTransactions(start : Int ,count : Int,callback :@escaping (Int,String,[String:Any])->()) -> Void
    {
        var pars : [String:String] = [:]
        pars["start"] = String(start)
        pars["count"] = String(count)
        
        Post(action: "transactions", params: pars){ (results) in
            let error : Int = results["error"] as! Int
            let message : String = results["message"] as! String
            var args : [String:Any] = [:]
            let transastions = results["transactions"] as? Transaction
            if error == 0
            {
                if transastions != nil
                {
                    args["transaction"] = transastions;
                }
            }
            callback(error,message,args)
        }
    }
}

public class GrdUser
{
    public var username : String = ""
    public var email : String = ""
    public var address : String = ""
    public var balance : Decimal = 0.0
    public var otp : Bool = false
}

public class LeaderBoardItem
{
    public var username : String = "";
    public var score : Double = 0;
    public var rank : Int = 0;
}
public class SessionData
{
    public var sessionid : Int = 0;
    public var sessionstart: Double = 0;
    public func GetTime() -> Date
    {
        var epochStart : Double  = Date().timeIntervalSince1970
        epochStart = epochStart + sessionstart
        return Date(timeIntervalSince1970: epochStart)
    }
    public var values : [String:String] = [:]
}

public enum TransactionType : Int
{
    case Base=1,Internal=2,External=3
}
public enum TransactionStatus : Int
{
    case Pending = 0, Success = 1, Error = 2
}
public class Transaction
{
    public var tx : String = ""
    public var from : String = ""
    public var to : String = ""
    public var amount : Decimal = 0.0
    public var transdate : Double = 0
    public var transtype : TransactionType = TransactionType.Base
    public var status : TransactionStatus = TransactionStatus.Pending
    public func GetTime() -> Date
    {
        var epochStart : Double  = Date().timeIntervalSince1970
        epochStart = epochStart + transdate
        return Date(timeIntervalSince1970: epochStart)
    }
}
