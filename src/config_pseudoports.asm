       ; ADD_PSEUDOPORT       0, \
       ;                      VDM=TRUE, \
       ;                      DATAPORT=3, \
       ;                      STATUSPORT=0, \
       ;                      READMASK=1, \
       ;                      READINVERT=TRUE

       ; ADD_PSEUDOPORT       1, \
       ;                      DATAPORT=11h, \
       ;                      STATUSPORT=10h, \
       ;                      READMASK=1, \
       ;                      WRITEMASK=2, \
       ;                      RESETMASK=3, \
       ;                      SETUPMASK=17 \


       ADD_PSEUDOPORT       0, \
                            VDM=TRUE, \
                            DATAPORT=5h, \
                            STATUSPORT=4h, \
                            READMASK=1, \
                            READINVERT=TRUE

       ADD_PSEUDOPORT       1, \
                            DATAPORT=1h, \
                            STATUSPORT=0h, \
                            READMASK=1, \
                            WRITEMASK=128, \
                            READINVERT=TRUE

