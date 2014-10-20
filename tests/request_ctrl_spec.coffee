describe "RequestCtrl", ->
  scope = undefined
  modalInstance =
    close: ->
    dismiss: ->
        
  beforeEach angular.mock.module("walletApp")
  
  beforeEach ->
    angular.mock.inject ($injector, localStorageService) ->
      localStorageService.remove("mockWallets")
      
      Wallet = $injector.get("Wallet")      
            
      MyWallet = $injector.get("MyWallet")
      
      Wallet.login("test", "test")  
    
      return

    return

  describe "when creating a new request", ->
    beforeEach ->
      angular.mock.inject((Wallet, $rootScope, $controller) ->
        scope = $rootScope.$new()
            
        $controller "RequestCtrl",
          $scope: scope,
          $stateParams: {},
          $modalInstance: modalInstance
          request: undefined
        
        scope.fields = {amount: "0", address: null, to: null}
      
        # Trigger generation of payment address:
        scope.fields.amount = "1"
        scope.$apply()
      )
      
    it "should have access to accounts",  inject(() ->
      expect(scope.accounts).toBeDefined()
      expect(scope.accounts.length).toBeGreaterThan(0)
    )
  
    it "should select first account by default",  inject((Wallet) ->

      expect(Wallet.accounts[0].label).toBe(scope.fields.to.label)
      expect(Wallet.accounts[0].balance).toBe(scope.fields.to.balance)
      expect(Wallet.accounts[0].balance).toBeGreaterThan(0)    
    )
  

  
    it "should have an address if the request is valid",  inject(() ->
        expect(scope.paymentRequest.address).toBe('1Q57Pa6UQiDBeA3o5sQR1orCqfZzGA7Ddp')
    )
  
    it "should simulate payment after 10 seconds in mock", inject(($timeout) ->
      expect(scope.alerts.length).toBe(0)    
      $timeout.flush(5000)
      # Don't interrupt...
      $timeout.flush(5000)
      expect(scope.alerts.length).toBe(1)
      expect(scope.paymentRequest.complete).toBe(true)
    
    )
  
    it "should cancel() delayed payment simulation", inject(($timeout) ->
      expect(scope.alerts.length).toBe(0)   
      $timeout.flush(5000)
      scope.cancel() 
      $timeout.flush(5000)
      expect(scope.alerts.length).toBe(0)
    )
  
    it "should cancel payment request when user presses cancel", inject((Wallet) ->
      before = Wallet.paymentRequests.length
      spyOn(Wallet, "cancelPaymentRequest").and.callThrough()
      scope.cancel()
      expect(Wallet.cancelPaymentRequest).toHaveBeenCalled()
      expect(scope.paymentRequest).toBeNull()
      expect(Wallet.paymentRequests.length).toBe(before - 1)
    )
  
    it "should update amount in request if changed in the form", inject(() ->
      scope.fields.amount = "0.1"
      scope.$apply()
      expect(scope.paymentRequest.amount.format("1")).toBe("10000000")
      
    )
  
    it "should allow user to accept incorrect amount", inject(() ->
      scope.paymentRequest.paid = scope.paymentRequest.amount.multiply(0.8)
      scope.$apply()
      expect(scope.paymentRequest.complete).toBe(false)
      scope.accept()
      expect(scope.paymentRequest.complete).toBe(true)
    )
  
  describe "when opening existing request", ->
    beforeEach ->
      angular.mock.inject((Wallet, $rootScope, $controller) ->
        Wallet.generatePaymentRequestForAccount(1, numeral(100000))
                
        scope = $rootScope.$new()
            
        $controller "RequestCtrl",
          $scope: scope,
          $stateParams: {},
          $modalInstance: modalInstance
          request: Wallet.paymentRequests[0] # Set payment request (which doesn't specify the account)

        scope.$apply()
        
      )
    
    it "should show the amount",  inject((Wallet) ->
      expect(scope.fields.amount).toBe("0.001")
    )
      
    it "should select the correct account ",  inject((Wallet) ->
      expect(scope.fields.to).toBe(Wallet.accounts[1])
    )
    
    it "should cancel payment request when user presses cancel", inject((Wallet) ->
      before = Wallet.paymentRequests.length
      spyOn(Wallet, "cancelPaymentRequest").and.callThrough()
      scope.cancel()
      expect(Wallet.cancelPaymentRequest).toHaveBeenCalled()
      expect(scope.paymentRequest).toBeNull()
      expect(Wallet.paymentRequests.length).toBe(before - 1)
    )