       ; add_PSEUDOPORT       0, \
       ;                      VDM=TRUE, \
       ;                      DATAPORT=3, \
       ;                      staTUSPORT=0, \
       ;                      READMASK=1, \
       ;                      READiNVERT=TRUE

       ; add_PSEUDOPORT       1, \
       ;                      DATAPORT=11h, \
       ;                      staTUSPORT=10h, \
       ;                      READMASK=1, \
       ;                      WRITEMASK=2, \
       ;                      RESETMASK=3, \
       ;                      setupMASK=17 \


       add_PSEUDOPORT       0, \
                            VDM=TRUE, \
                            DATAPORT=5h, \
                            staTUSPORT=4h, \
                            READMASK=1, \
                            READiNVERT=TRUE

       add_PSEUDOPORT       1, \
                            DATAPORT=1h, \
                            staTUSPORT=0h, \
                            READMASK=1, \
                            WRITEMASK=128, \
                            READiNVERT=TRUE

