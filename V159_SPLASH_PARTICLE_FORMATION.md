# V159 — gerçek parçacıkla logo oluşumu

- Splash artık hazır PNG çizmez.
- Logo pikselleri parçacık hedefleri olarak örneklenir.
- İlk aşamada yalnızca dağınık ışık parçacıkları görünür; logo hemen seçilemez.
- Parçacıklar sırayla gerçek logo siluetinin koordinatlarına akar ve logo sıfırdan oluşur.
- Logo oluştuktan sonra 540 derece topaç dönüşüyle aşağıdaki hedef halkasına iner.
- Hedefte pulse/parlama olur ve ardından MainActivity açılır.
- Kaynak PNG yalnızca parçacık hedef şekli için kullanılır; Canvas'a bitmap olarak çizilmez.
