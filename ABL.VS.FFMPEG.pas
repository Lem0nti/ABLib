unit ABL.VS.FFMPEG;

interface

{$I LibAVHeaders/CompilerDefines.inc}

const
  AV_NUM_DATA_POINTERS = 8;

  {$IFDEF UNIX}                     
  AVCODEC_LIBNAME = 'avcodec';
  AVUTIL_LIBNAME  = 'avutil';
  SWSCALE_LIBNAME = 'swscale';
  {$ELSE}
  AVCODEC_LIBNAME = 'avcodec-58.dll';
  AVUTIL_LIBNAME  = 'avutil-56.dll';
  SWSCALE_LIBNAME = 'swscale-5.dll';
  {$ENDIF}
  SWS_BICUBIC       = $0004;

type
  PPByte = ^PByte;
  Size_t = NativeUInt;
  Int = Integer;

  TAVPacketSideDataType = (
    AV_PKT_DATA_PALETTE,
    AV_PKT_DATA_NEW_EXTRADATA,
    AV_PKT_DATA_PARAM_CHANGE,
    AV_PKT_DATA_H263_MB_INFO,
    AV_PKT_DATA_REPLAYGAIN,
    AV_PKT_DATA_DISPLAYMATRIX,
    AV_PKT_DATA_STEREO3D,
    AV_PKT_DATA_AUDIO_SERVICE_TYPE,
    AV_PKT_DATA_QUALITY_STATS,
    AV_PKT_DATA_FALLBACK_TRACK,
    AV_PKT_DATA_CPB_PROPERTIES,
    AV_PKT_DATA_SKIP_SAMPLES,
    AV_PKT_DATA_JP_DUALMONO,
    AV_PKT_DATA_STRINGS_METADATA,
    AV_PKT_DATA_SUBTITLE_POSITION,
    AV_PKT_DATA_MATROSKA_BLOCKADDITIONAL,
    AV_PKT_DATA_WEBVTT_IDENTIFIER,
    AV_PKT_DATA_WEBVTT_SETTINGS,
    AV_PKT_DATA_METADATA_UPDATE,
    AV_PKT_DATA_MPEGTS_STREAM_ID,
    AV_PKT_DATA_MASTERING_DISPLAY_METADATA,
    AV_PKT_DATA_SPHERICAL,
    AV_PKT_DATA_CONTENT_LIGHT_LEVEL,
    AV_PKT_DATA_A53_CC,
    AV_PKT_DATA_ENCRYPTION_INIT_INFO,
    AV_PKT_DATA_ENCRYPTION_INFO,
    AV_PKT_DATA_AFD,
    AV_PKT_DATA_NB
  );

  TAVPictureType = (
    AV_PICTURE_TYPE_NONE = 0,
    AV_PICTURE_TYPE_I,
    AV_PICTURE_TYPE_P,
    AV_PICTURE_TYPE_B,
    AV_PICTURE_TYPE_S,
    AV_PICTURE_TYPE_SI,
    AV_PICTURE_TYPE_SP,
    AV_PICTURE_TYPE_BI
  );

  TAVFrameSideDataType = (
    AV_FRAME_DATA_PANSCAN,
    AV_FRAME_DATA_A53_CC,
    AV_FRAME_DATA_STEREO3D,
    AV_FRAME_DATA_MATRIXENCODING,
    AV_FRAME_DATA_DOWNMIX_INFO,
    AV_FRAME_DATA_REPLAYGAIN,
    AV_FRAME_DATA_DISPLAYMATRIX,
    AV_FRAME_DATA_AFD,
    AV_FRAME_DATA_MOTION_VECTORS,
    AV_FRAME_DATA_SKIP_SAMPLES,
    AV_FRAME_DATA_AUDIO_SERVICE_TYPE,
    AV_FRAME_DATA_MASTERING_DISPLAY_METADATA,
    AV_FRAME_DATA_GOP_TIMECODE,
    AV_FRAME_DATA_SPHERICAL,
    AV_FRAME_DATA_CONTENT_LIGHT_LEVEL,
    AV_FRAME_DATA_ICC_PROFILE,
{$IFDEF FF_API_FRAME_QP}
    AV_FRAME_DATA_QP_TABLE_PROPERTIES,
    AV_FRAME_DATA_QP_TABLE_DATA,
{$ENDIF}
    AV_FRAME_DATA_S12M_TIMECODE,
    AV_FRAME_DATA_DYNAMIC_HDR_PLUS,
    AV_FRAME_DATA_REGIONS_OF_INTEREST
  );

  TAVColorRange = (
    AVCOL_RANGE_UNSPECIFIED = 0,
    AVCOL_RANGE_MPEG        = 1,
    AVCOL_RANGE_JPEG        = 2,
    AVCOL_RANGE_NB
  );

  TAVColorPrimaries = (
    AVCOL_PRI_RESERVED0   = 0,
    AVCOL_PRI_BT709       = 1,
    AVCOL_PRI_UNSPECIFIED = 2,
    AVCOL_PRI_RESERVED    = 3,
    AVCOL_PRI_BT470M      = 4,
    AVCOL_PRI_BT470BG     = 5,
    AVCOL_PRI_SMPTE170M   = 6,
    AVCOL_PRI_SMPTE240M   = 7,
    AVCOL_PRI_FILM        = 8,
    AVCOL_PRI_BT2020      = 9,
    AVCOL_PRI_SMPTE428    = 10,
    AVCOL_PRI_SMPTEST428_1= AVCOL_PRI_SMPTE428,
    AVCOL_PRI_SMPTE431    = 11,
    AVCOL_PRI_SMPTE432    = 12,
    AVCOL_PRI_JEDEC_P22   = 22,
    AVCOL_PRI_NB
  );

  TAVColorTransferCharacteristic = (
    AVCOL_TRC_RESERVED0    = 0,
    AVCOL_TRC_BT709        = 1,
    AVCOL_TRC_UNSPECIFIED  = 2,
    AVCOL_TRC_RESERVED     = 3,
    AVCOL_TRC_GAMMA22      = 4,
    AVCOL_TRC_GAMMA28      = 5,
    AVCOL_TRC_SMPTE170M    = 6,
    AVCOL_TRC_SMPTE240M    = 7,
    AVCOL_TRC_LINEAR       = 8,
    AVCOL_TRC_LOG          = 9,
    AVCOL_TRC_LOG_SQRT     = 10,
    AVCOL_TRC_IEC61966_2_4 = 11,
    AVCOL_TRC_BT1361_ECG   = 12,
    AVCOL_TRC_IEC61966_2_1 = 13,
    AVCOL_TRC_BT2020_10    = 14,
    AVCOL_TRC_BT2020_12    = 15,
    AVCOL_TRC_SMPTE2084    = 16,
    AVCOL_TRC_SMPTEST2084  = AVCOL_TRC_SMPTE2084,
    AVCOL_TRC_SMPTE428     = 17,
    AVCOL_TRC_SMPTEST428_1 = AVCOL_TRC_SMPTE428,
    AVCOL_TRC_ARIB_STD_B67 = 18,
    AVCOL_TRC_NB
  );

  TAVColorSpace = (
    AVCOL_SPC_RGB         = 0,
    AVCOL_SPC_BT709       = 1,
    AVCOL_SPC_UNSPECIFIED = 2,
    AVCOL_SPC_RESERVED    = 3,
    AVCOL_SPC_FCC         = 4,
    AVCOL_SPC_BT470BG     = 5,
    AVCOL_SPC_SMPTE170M   = 6,
    AVCOL_SPC_SMPTE240M   = 7,
    AVCOL_SPC_YCGCO       = 8,
    AVCOL_SPC_YCOCG       = AVCOL_SPC_YCGCO,
    AVCOL_SPC_BT2020_NCL  = 9,
    AVCOL_SPC_BT2020_CL   = 10,
    AVCOL_SPC_SMPTE2085   = 11,
    AVCOL_SPC_CHROMA_DERIVED_NCL = 12,
    AVCOL_SPC_CHROMA_DERIVED_CL = 13,
    AVCOL_SPC_ICTCP       = 14,
    AVCOL_SPC_NB
  );

  TAVChromaLocation = (
    AVCHROMA_LOC_UNSPECIFIED = 0,
    AVCHROMA_LOC_LEFT        = 1,
    AVCHROMA_LOC_CENTER      = 2,
    AVCHROMA_LOC_TOPLEFT     = 3,
    AVCHROMA_LOC_TOP         = 4,
    AVCHROMA_LOC_BOTTOMLEFT  = 5,
    AVCHROMA_LOC_BOTTOM      = 6,
    AVCHROMA_LOC_NB
  );

  PAVCodecID = ^TAVCodecID;
  TAVCodecID = (
    AV_CODEC_ID_NONE,
    AV_CODEC_ID_MPEG1VIDEO,
    AV_CODEC_ID_MPEG2VIDEO,
    AV_CODEC_ID_H261,
    AV_CODEC_ID_H263,
    AV_CODEC_ID_RV10,
    AV_CODEC_ID_RV20,
    AV_CODEC_ID_MJPEG,
    AV_CODEC_ID_MJPEGB,
    AV_CODEC_ID_LJPEG,
    AV_CODEC_ID_SP5X,
    AV_CODEC_ID_JPEGLS,
    AV_CODEC_ID_MPEG4,
    AV_CODEC_ID_RAWVIDEO,
    AV_CODEC_ID_MSMPEG4V1,
    AV_CODEC_ID_MSMPEG4V2,
    AV_CODEC_ID_MSMPEG4V3,
    AV_CODEC_ID_WMV1,
    AV_CODEC_ID_WMV2,
    AV_CODEC_ID_H263P,
    AV_CODEC_ID_H263I,
    AV_CODEC_ID_FLV1,
    AV_CODEC_ID_SVQ1,
    AV_CODEC_ID_SVQ3,
    AV_CODEC_ID_DVVIDEO,
    AV_CODEC_ID_HUFFYUV,
    AV_CODEC_ID_CYUV,
    AV_CODEC_ID_H264,
    AV_CODEC_ID_INDEO3,
    AV_CODEC_ID_VP3,
    AV_CODEC_ID_THEORA,
    AV_CODEC_ID_ASV1,
    AV_CODEC_ID_ASV2,
    AV_CODEC_ID_FFV1,
    AV_CODEC_ID_4XM,
    AV_CODEC_ID_VCR1,
    AV_CODEC_ID_CLJR,
    AV_CODEC_ID_MDEC,
    AV_CODEC_ID_ROQ,
    AV_CODEC_ID_INTERPLAY_VIDEO,
    AV_CODEC_ID_XAN_WC3,
    AV_CODEC_ID_XAN_WC4,
    AV_CODEC_ID_RPZA,
    AV_CODEC_ID_CINEPAK,
    AV_CODEC_ID_WS_VQA,
    AV_CODEC_ID_MSRLE,
    AV_CODEC_ID_MSVIDEO1,
    AV_CODEC_ID_IDCIN,
    AV_CODEC_ID_8BPS,
    AV_CODEC_ID_SMC,
    AV_CODEC_ID_FLIC,
    AV_CODEC_ID_TRUEMOTION1,
    AV_CODEC_ID_VMDVIDEO,
    AV_CODEC_ID_MSZH,
    AV_CODEC_ID_ZLIB,
    AV_CODEC_ID_QTRLE,
    AV_CODEC_ID_TSCC,
    AV_CODEC_ID_ULTI,
    AV_CODEC_ID_QDRAW,
    AV_CODEC_ID_VIXL,
    AV_CODEC_ID_QPEG,
    AV_CODEC_ID_PNG,
    AV_CODEC_ID_PPM,
    AV_CODEC_ID_PBM,
    AV_CODEC_ID_PGM,
    AV_CODEC_ID_PGMYUV,
    AV_CODEC_ID_PAM,
    AV_CODEC_ID_FFVHUFF,
    AV_CODEC_ID_RV30,
    AV_CODEC_ID_RV40,
    AV_CODEC_ID_VC1,
    AV_CODEC_ID_WMV3,
    AV_CODEC_ID_LOCO,
    AV_CODEC_ID_WNV1,
    AV_CODEC_ID_AASC,
    AV_CODEC_ID_INDEO2,
    AV_CODEC_ID_FRAPS,
    AV_CODEC_ID_TRUEMOTION2,
    AV_CODEC_ID_BMP,
    AV_CODEC_ID_CSCD,
    AV_CODEC_ID_MMVIDEO,
    AV_CODEC_ID_ZMBV,
    AV_CODEC_ID_AVS,
    AV_CODEC_ID_SMACKVIDEO,
    AV_CODEC_ID_NUV,
    AV_CODEC_ID_KMVC,
    AV_CODEC_ID_FLASHSV,
    AV_CODEC_ID_CAVS,
    AV_CODEC_ID_JPEG2000,
    AV_CODEC_ID_VMNC,
    AV_CODEC_ID_VP5,
    AV_CODEC_ID_VP6,
    AV_CODEC_ID_VP6F,
    AV_CODEC_ID_TARGA,
    AV_CODEC_ID_DSICINVIDEO,
    AV_CODEC_ID_TIERTEXSEQVIDEO,
    AV_CODEC_ID_TIFF,
    AV_CODEC_ID_GIF,
    AV_CODEC_ID_DXA,
    AV_CODEC_ID_DNXHD,
    AV_CODEC_ID_THP,
    AV_CODEC_ID_SGI,
    AV_CODEC_ID_C93,
    AV_CODEC_ID_BETHSOFTVID,
    AV_CODEC_ID_PTX,
    AV_CODEC_ID_TXD,
    AV_CODEC_ID_VP6A,
    AV_CODEC_ID_AMV,
    AV_CODEC_ID_VB,
    AV_CODEC_ID_PCX,
    AV_CODEC_ID_SUNRAST,
    AV_CODEC_ID_INDEO4,
    AV_CODEC_ID_INDEO5,
    AV_CODEC_ID_MIMIC,
    AV_CODEC_ID_RL2,
    AV_CODEC_ID_ESCAPE124,
    AV_CODEC_ID_DIRAC,
    AV_CODEC_ID_BFI,
    AV_CODEC_ID_CMV,
    AV_CODEC_ID_MOTIONPIXELS,
    AV_CODEC_ID_TGV,
    AV_CODEC_ID_TGQ,
    AV_CODEC_ID_TQI,
    AV_CODEC_ID_AURA,
    AV_CODEC_ID_AURA2,
    AV_CODEC_ID_V210X,
    AV_CODEC_ID_TMV,
    AV_CODEC_ID_V210,
    AV_CODEC_ID_DPX,
    AV_CODEC_ID_MAD,
    AV_CODEC_ID_FRWU,
    AV_CODEC_ID_FLASHSV2,
    AV_CODEC_ID_CDGRAPHICS,
    AV_CODEC_ID_R210,
    AV_CODEC_ID_ANM,
    AV_CODEC_ID_BINKVIDEO,
    AV_CODEC_ID_IFF_ILBM,
    AV_CODEC_ID_KGV1,
    AV_CODEC_ID_YOP,
    AV_CODEC_ID_VP8,
    AV_CODEC_ID_PICTOR,
    AV_CODEC_ID_ANSI,
    AV_CODEC_ID_A64_MULTI,
    AV_CODEC_ID_A64_MULTI5,
    AV_CODEC_ID_R10K,
    AV_CODEC_ID_MXPEG,
    AV_CODEC_ID_LAGARITH,
    AV_CODEC_ID_PRORES,
    AV_CODEC_ID_JV,
    AV_CODEC_ID_DFA,
    AV_CODEC_ID_WMV3IMAGE,
    AV_CODEC_ID_VC1IMAGE,
    AV_CODEC_ID_UTVIDEO,
    AV_CODEC_ID_BMV_VIDEO,
    AV_CODEC_ID_VBLE,
    AV_CODEC_ID_DXTORY,
    AV_CODEC_ID_V410,
    AV_CODEC_ID_XWD,
    AV_CODEC_ID_CDXL,
    AV_CODEC_ID_XBM,
    AV_CODEC_ID_ZEROCODEC,
    AV_CODEC_ID_MSS1,
    AV_CODEC_ID_MSA1,
    AV_CODEC_ID_TSCC2,
    AV_CODEC_ID_MTS2,
    AV_CODEC_ID_CLLC,
    AV_CODEC_ID_MSS2,
    AV_CODEC_ID_VP9,
    AV_CODEC_ID_AIC,
    AV_CODEC_ID_ESCAPE130,
    AV_CODEC_ID_G2M,
    AV_CODEC_ID_WEBP,
    AV_CODEC_ID_HNM4_VIDEO,
    AV_CODEC_ID_HEVC,
    AV_CODEC_ID_FIC,
    AV_CODEC_ID_ALIAS_PIX,
    AV_CODEC_ID_BRENDER_PIX,
    AV_CODEC_ID_PAF_VIDEO,
    AV_CODEC_ID_EXR,
    AV_CODEC_ID_VP7,
    AV_CODEC_ID_SANM,
    AV_CODEC_ID_SGIRLE,
    AV_CODEC_ID_MVC1,
    AV_CODEC_ID_MVC2,
    AV_CODEC_ID_HQX,
    AV_CODEC_ID_TDSC,
    AV_CODEC_ID_HQ_HQA,
    AV_CODEC_ID_HAP,
    AV_CODEC_ID_DDS,
    AV_CODEC_ID_DXV,
    AV_CODEC_ID_SCREENPRESSO,
    AV_CODEC_ID_RSCC,
    AV_CODEC_ID_AVS2,
    AV_CODEC_ID_Y41P = $8000,
    AV_CODEC_ID_AVRP,
    AV_CODEC_ID_012V,
    AV_CODEC_ID_AVUI,
    AV_CODEC_ID_AYUV,
    AV_CODEC_ID_TARGA_Y216,
    AV_CODEC_ID_V308,
    AV_CODEC_ID_V408,
    AV_CODEC_ID_YUV4,
    AV_CODEC_ID_AVRN,
    AV_CODEC_ID_CPIA,
    AV_CODEC_ID_XFACE,
    AV_CODEC_ID_SNOW,
    AV_CODEC_ID_SMVJPEG,
    AV_CODEC_ID_APNG,
    AV_CODEC_ID_DAALA,
    AV_CODEC_ID_CFHD,
    AV_CODEC_ID_TRUEMOTION2RT,
    AV_CODEC_ID_M101,
    AV_CODEC_ID_MAGICYUV,
    AV_CODEC_ID_SHEERVIDEO,
    AV_CODEC_ID_YLC,
    AV_CODEC_ID_PSD,
    AV_CODEC_ID_PIXLET,
    AV_CODEC_ID_SPEEDHQ,
    AV_CODEC_ID_FMVC,
    AV_CODEC_ID_SCPR,
    AV_CODEC_ID_CLEARVIDEO,
    AV_CODEC_ID_XPM,
    AV_CODEC_ID_AV1,
    AV_CODEC_ID_BITPACKED,
    AV_CODEC_ID_MSCC,
    AV_CODEC_ID_SRGC,
    AV_CODEC_ID_SVG,
    AV_CODEC_ID_GDV,
    AV_CODEC_ID_FITS,
    AV_CODEC_ID_IMM4,
    AV_CODEC_ID_PROSUMER,
    AV_CODEC_ID_MWSC,
    AV_CODEC_ID_WCMV,
    AV_CODEC_ID_RASC,
    AV_CODEC_ID_HYMT,
    AV_CODEC_ID_ARBC,
    AV_CODEC_ID_AGM,
    AV_CODEC_ID_LSCR,
    AV_CODEC_ID_VP4,
{$IFNDEF FPC}
    AV_CODEC_ID_FIRST_AUDIO = $10000,
{$ENDIF}
    AV_CODEC_ID_PCM_S16LE = $10000,
    AV_CODEC_ID_PCM_S16BE,
    AV_CODEC_ID_PCM_U16LE,
    AV_CODEC_ID_PCM_U16BE,
    AV_CODEC_ID_PCM_S8,
    AV_CODEC_ID_PCM_U8,
    AV_CODEC_ID_PCM_MULAW,
    AV_CODEC_ID_PCM_ALAW,
    AV_CODEC_ID_PCM_S32LE,
    AV_CODEC_ID_PCM_S32BE,
    AV_CODEC_ID_PCM_U32LE,
    AV_CODEC_ID_PCM_U32BE,
    AV_CODEC_ID_PCM_S24LE,
    AV_CODEC_ID_PCM_S24BE,
    AV_CODEC_ID_PCM_U24LE,
    AV_CODEC_ID_PCM_U24BE,
    AV_CODEC_ID_PCM_S24DAUD,
    AV_CODEC_ID_PCM_ZORK,
    AV_CODEC_ID_PCM_S16LE_PLANAR,
    AV_CODEC_ID_PCM_DVD,
    AV_CODEC_ID_PCM_F32BE,
    AV_CODEC_ID_PCM_F32LE,
    AV_CODEC_ID_PCM_F64BE,
    AV_CODEC_ID_PCM_F64LE,
    AV_CODEC_ID_PCM_BLURAY,
    AV_CODEC_ID_PCM_LXF,
    AV_CODEC_ID_S302M,
    AV_CODEC_ID_PCM_S8_PLANAR,
    AV_CODEC_ID_PCM_S24LE_PLANAR,
    AV_CODEC_ID_PCM_S32LE_PLANAR,
    AV_CODEC_ID_PCM_S16BE_PLANAR,
    AV_CODEC_ID_PCM_S64LE = $10800,
    AV_CODEC_ID_PCM_S64BE,
    AV_CODEC_ID_PCM_F16LE,
    AV_CODEC_ID_PCM_F24LE,
    AV_CODEC_ID_PCM_VIDC,
    AV_CODEC_ID_ADPCM_IMA_QT = $11000,
    AV_CODEC_ID_ADPCM_IMA_WAV,
    AV_CODEC_ID_ADPCM_IMA_DK3,
    AV_CODEC_ID_ADPCM_IMA_DK4,
    AV_CODEC_ID_ADPCM_IMA_WS,
    AV_CODEC_ID_ADPCM_IMA_SMJPEG,
    AV_CODEC_ID_ADPCM_MS,
    AV_CODEC_ID_ADPCM_4XM,
    AV_CODEC_ID_ADPCM_XA,
    AV_CODEC_ID_ADPCM_ADX,
    AV_CODEC_ID_ADPCM_EA,
    AV_CODEC_ID_ADPCM_G726,
    AV_CODEC_ID_ADPCM_CT,
    AV_CODEC_ID_ADPCM_SWF,
    AV_CODEC_ID_ADPCM_YAMAHA,
    AV_CODEC_ID_ADPCM_SBPRO_4,
    AV_CODEC_ID_ADPCM_SBPRO_3,
    AV_CODEC_ID_ADPCM_SBPRO_2,
    AV_CODEC_ID_ADPCM_THP,
    AV_CODEC_ID_ADPCM_IMA_AMV,
    AV_CODEC_ID_ADPCM_EA_R1,
    AV_CODEC_ID_ADPCM_EA_R3,
    AV_CODEC_ID_ADPCM_EA_R2,
    AV_CODEC_ID_ADPCM_IMA_EA_SEAD,
    AV_CODEC_ID_ADPCM_IMA_EA_EACS,
    AV_CODEC_ID_ADPCM_EA_XAS,
    AV_CODEC_ID_ADPCM_EA_MAXIS_XA,
    AV_CODEC_ID_ADPCM_IMA_ISS,
    AV_CODEC_ID_ADPCM_G722,
    AV_CODEC_ID_ADPCM_IMA_APC,
    AV_CODEC_ID_ADPCM_VIMA,
    AV_CODEC_ID_ADPCM_AFC = $11800,
    AV_CODEC_ID_ADPCM_IMA_OKI,
    AV_CODEC_ID_ADPCM_DTK,
    AV_CODEC_ID_ADPCM_IMA_RAD,
    AV_CODEC_ID_ADPCM_G726LE,
    AV_CODEC_ID_ADPCM_THP_LE,
    AV_CODEC_ID_ADPCM_PSX,
    AV_CODEC_ID_ADPCM_AICA,
    AV_CODEC_ID_ADPCM_IMA_DAT4,
    AV_CODEC_ID_ADPCM_MTAF,
    AV_CODEC_ID_ADPCM_AGM,
    AV_CODEC_ID_AMR_NB = $12000,
    AV_CODEC_ID_AMR_WB,
    AV_CODEC_ID_RA_144 = $13000,
    AV_CODEC_ID_RA_288,
    AV_CODEC_ID_ROQ_DPCM = $14000,
    AV_CODEC_ID_INTERPLAY_DPCM,
    AV_CODEC_ID_XAN_DPCM,
    AV_CODEC_ID_SOL_DPCM,
    AV_CODEC_ID_SDX2_DPCM = $14800,
    AV_CODEC_ID_GREMLIN_DPCM,
    AV_CODEC_ID_MP2 = $15000,
    AV_CODEC_ID_MP3,
    AV_CODEC_ID_AAC,
    AV_CODEC_ID_AC3,
    AV_CODEC_ID_DTS,
    AV_CODEC_ID_VORBIS,
    AV_CODEC_ID_DVAUDIO,
    AV_CODEC_ID_WMAV1,
    AV_CODEC_ID_WMAV2,
    AV_CODEC_ID_MACE3,
    AV_CODEC_ID_MACE6,
    AV_CODEC_ID_VMDAUDIO,
    AV_CODEC_ID_FLAC,
    AV_CODEC_ID_MP3ADU,
    AV_CODEC_ID_MP3ON4,
    AV_CODEC_ID_SHORTEN,
    AV_CODEC_ID_ALAC,
    AV_CODEC_ID_WESTWOOD_SND1,
    AV_CODEC_ID_GSM,
    AV_CODEC_ID_QDM2,
    AV_CODEC_ID_COOK,
    AV_CODEC_ID_TRUESPEECH,
    AV_CODEC_ID_TTA,
    AV_CODEC_ID_SMACKAUDIO,
    AV_CODEC_ID_QCELP,
    AV_CODEC_ID_WAVPACK,
    AV_CODEC_ID_DSICINAUDIO,
    AV_CODEC_ID_IMC,
    AV_CODEC_ID_MUSEPACK7,
    AV_CODEC_ID_MLP,
    AV_CODEC_ID_GSM_MS,
    AV_CODEC_ID_ATRAC3,
    AV_CODEC_ID_APE,
    AV_CODEC_ID_NELLYMOSER,
    AV_CODEC_ID_MUSEPACK8,
    AV_CODEC_ID_SPEEX,
    AV_CODEC_ID_WMAVOICE,
    AV_CODEC_ID_WMAPRO,
    AV_CODEC_ID_WMALOSSLESS,
    AV_CODEC_ID_ATRAC3P,
    AV_CODEC_ID_EAC3,
    AV_CODEC_ID_SIPR,
    AV_CODEC_ID_MP1,
    AV_CODEC_ID_TWINVQ,
    AV_CODEC_ID_TRUEHD,
    AV_CODEC_ID_MP4ALS,
    AV_CODEC_ID_ATRAC1,
    AV_CODEC_ID_BINKAUDIO_RDFT,
    AV_CODEC_ID_BINKAUDIO_DCT,
    AV_CODEC_ID_AAC_LATM,
    AV_CODEC_ID_QDMC,
    AV_CODEC_ID_CELT,
    AV_CODEC_ID_G723_1,
    AV_CODEC_ID_G729,
    AV_CODEC_ID_8SVX_EXP,
    AV_CODEC_ID_8SVX_FIB,
    AV_CODEC_ID_BMV_AUDIO,
    AV_CODEC_ID_RALF,
    AV_CODEC_ID_IAC,
    AV_CODEC_ID_ILBC,
    AV_CODEC_ID_OPUS,
    AV_CODEC_ID_COMFORT_NOISE,
    AV_CODEC_ID_TAK,
    AV_CODEC_ID_METASOUND,
    AV_CODEC_ID_PAF_AUDIO,
    AV_CODEC_ID_ON2AVC,
    AV_CODEC_ID_DSS_SP,
    AV_CODEC_ID_CODEC2,
    AV_CODEC_ID_FFWAVESYNTH = $15800,
    AV_CODEC_ID_SONIC,
    AV_CODEC_ID_SONIC_LS,
    AV_CODEC_ID_EVRC,
    AV_CODEC_ID_SMV,
    AV_CODEC_ID_DSD_LSBF,
    AV_CODEC_ID_DSD_MSBF,
    AV_CODEC_ID_DSD_LSBF_PLANAR,
    AV_CODEC_ID_DSD_MSBF_PLANAR,
    AV_CODEC_ID_4GV,
    AV_CODEC_ID_INTERPLAY_ACM,
    AV_CODEC_ID_XMA1,
    AV_CODEC_ID_XMA2,
    AV_CODEC_ID_DST,
    AV_CODEC_ID_ATRAC3AL,
    AV_CODEC_ID_ATRAC3PAL,
    AV_CODEC_ID_DOLBY_E,
    AV_CODEC_ID_APTX,
    AV_CODEC_ID_APTX_HD,
    AV_CODEC_ID_SBC,
    AV_CODEC_ID_ATRAC9,
    AV_CODEC_ID_HCOM,
{$IFNDEF FPC}
    AV_CODEC_ID_FIRST_SUBTITLE = $17000,
{$ENDIF}
    AV_CODEC_ID_DVD_SUBTITLE = $17000,
    AV_CODEC_ID_DVB_SUBTITLE,
    AV_CODEC_ID_TEXT,
    AV_CODEC_ID_XSUB,
    AV_CODEC_ID_SSA,
    AV_CODEC_ID_MOV_TEXT,
    AV_CODEC_ID_HDMV_PGS_SUBTITLE,
    AV_CODEC_ID_DVB_TELETEXT,
    AV_CODEC_ID_SRT,
    AV_CODEC_ID_MICRODVD   = $17800,
    AV_CODEC_ID_EIA_608,
    AV_CODEC_ID_JACOSUB,
    AV_CODEC_ID_SAMI,
    AV_CODEC_ID_REALTEXT,
    AV_CODEC_ID_STL,
    AV_CODEC_ID_SUBVIEWER1,
    AV_CODEC_ID_SUBVIEWER,
    AV_CODEC_ID_SUBRIP,
    AV_CODEC_ID_WEBVTT,
    AV_CODEC_ID_MPL2,
    AV_CODEC_ID_VPLAYER,
    AV_CODEC_ID_PJS,
    AV_CODEC_ID_ASS,
    AV_CODEC_ID_HDMV_TEXT_SUBTITLE,
    AV_CODEC_ID_TTML,
    AV_CODEC_ID_ARIB_CAPTION,
{$IFNDEF FPC}
    AV_CODEC_ID_FIRST_UNKNOWN = $18000,           ///< A dummy ID pointing at the start of various fake codecs.
{$ENDIF}
    AV_CODEC_ID_TTF = $18000,
    AV_CODEC_ID_SCTE_35,
    AV_CODEC_ID_BINTEXT    = $18800,
    AV_CODEC_ID_XBIN,
    AV_CODEC_ID_IDF,
    AV_CODEC_ID_OTF,
    AV_CODEC_ID_SMPTE_KLV,
    AV_CODEC_ID_DVD_NAV,
    AV_CODEC_ID_TIMED_ID3,
    AV_CODEC_ID_BIN_DATA,
    AV_CODEC_ID_PROBE = $19000,
    AV_CODEC_ID_MPEG2TS = $20000,
    AV_CODEC_ID_MPEG4SYSTEMS = $20001,
    AV_CODEC_ID_FFMETADATA = $21000,
    AV_CODEC_ID_WRAPPED_AVFRAME = $21001
  );

  TAVMediaType = (
    AVMEDIA_TYPE_UNKNOWN = -1,
    AVMEDIA_TYPE_VIDEO,
    AVMEDIA_TYPE_AUDIO,
    AVMEDIA_TYPE_DATA,
    AVMEDIA_TYPE_SUBTITLE,
    AVMEDIA_TYPE_ATTACHMENT,
    AVMEDIA_TYPE_NB
  );

  PPAVPixelFormat = ^PAVPixelFormat;
  PAVPixelFormat = ^TAVPixelFormat;
  TAVPixelFormat = (
    AV_PIX_FMT_NONE = -1,
    AV_PIX_FMT_YUV420P,
    AV_PIX_FMT_YUYV422,
    AV_PIX_FMT_RGB24,
    AV_PIX_FMT_BGR24,
    AV_PIX_FMT_YUV422P,
    AV_PIX_FMT_YUV444P,
    AV_PIX_FMT_YUV410P,
    AV_PIX_FMT_YUV411P,
    AV_PIX_FMT_GRAY8,
    AV_PIX_FMT_MONOWHITE,
    AV_PIX_FMT_MONOBLACK,
    AV_PIX_FMT_PAL8,
    AV_PIX_FMT_YUVJ420P,
    AV_PIX_FMT_YUVJ422P,
    AV_PIX_FMT_YUVJ444P,
    AV_PIX_FMT_UYVY422,
    AV_PIX_FMT_UYYVYY411,
    AV_PIX_FMT_BGR8,
    AV_PIX_FMT_BGR4,
    AV_PIX_FMT_BGR4_BYTE,
    AV_PIX_FMT_RGB8,
    AV_PIX_FMT_RGB4,
    AV_PIX_FMT_RGB4_BYTE,
    AV_PIX_FMT_NV12,
    AV_PIX_FMT_NV21,
    AV_PIX_FMT_ARGB,
    AV_PIX_FMT_RGBA,
    AV_PIX_FMT_ABGR,
    AV_PIX_FMT_BGRA,
    AV_PIX_FMT_GRAY16BE,
    AV_PIX_FMT_GRAY16LE,
    AV_PIX_FMT_YUV440P,
    AV_PIX_FMT_YUVJ440P,
    AV_PIX_FMT_YUVA420P,
    AV_PIX_FMT_RGB48BE,
    AV_PIX_FMT_RGB48LE,
    AV_PIX_FMT_RGB565BE,
    AV_PIX_FMT_RGB565LE,
    AV_PIX_FMT_RGB555BE,
    AV_PIX_FMT_RGB555LE,
    AV_PIX_FMT_BGR565BE,
    AV_PIX_FMT_BGR565LE,
    AV_PIX_FMT_BGR555BE,
    AV_PIX_FMT_BGR555LE,
{$IFDEF FF_API_VAAPI}
    AV_PIX_FMT_VAAPI_MOCO,
    AV_PIX_FMT_VAAPI_IDCT,
    AV_PIX_FMT_VAAPI_VLD,
    AV_PIX_FMT_VAAPI = AV_PIX_FMT_VAAPI_VLD,
{$ELSE}
    AV_PIX_FMT_VAAPI,
{$ENDIF}
    AV_PIX_FMT_YUV420P16LE,
    AV_PIX_FMT_YUV420P16BE,
    AV_PIX_FMT_YUV422P16LE,
    AV_PIX_FMT_YUV422P16BE,
    AV_PIX_FMT_YUV444P16LE,
    AV_PIX_FMT_YUV444P16BE,
    AV_PIX_FMT_DXVA2_VLD,
    AV_PIX_FMT_RGB444LE,
    AV_PIX_FMT_RGB444BE,
    AV_PIX_FMT_BGR444LE,
    AV_PIX_FMT_BGR444BE,
    AV_PIX_FMT_YA8,
    AV_PIX_FMT_BGR48BE,
    AV_PIX_FMT_BGR48LE,
    AV_PIX_FMT_YUV420P9BE,
    AV_PIX_FMT_YUV420P9LE,
    AV_PIX_FMT_YUV420P10BE,
    AV_PIX_FMT_YUV420P10LE,
    AV_PIX_FMT_YUV422P10BE,
    AV_PIX_FMT_YUV422P10LE,
    AV_PIX_FMT_YUV444P9BE,
    AV_PIX_FMT_YUV444P9LE,
    AV_PIX_FMT_YUV444P10BE,
    AV_PIX_FMT_YUV444P10LE,
    AV_PIX_FMT_YUV422P9BE,
    AV_PIX_FMT_YUV422P9LE,
    AV_PIX_FMT_GBRP,
    AV_PIX_FMT_GBRP9BE,
    AV_PIX_FMT_GBRP9LE,
    AV_PIX_FMT_GBRP10BE,
    AV_PIX_FMT_GBRP10LE,
    AV_PIX_FMT_GBRP16BE,
    AV_PIX_FMT_GBRP16LE,
    AV_PIX_FMT_YUVA422P,
    AV_PIX_FMT_YUVA444P,
    AV_PIX_FMT_YUVA420P9BE,
    AV_PIX_FMT_YUVA420P9LE,
    AV_PIX_FMT_YUVA422P9BE,
    AV_PIX_FMT_YUVA422P9LE,
    AV_PIX_FMT_YUVA444P9BE,
    AV_PIX_FMT_YUVA444P9LE,
    AV_PIX_FMT_YUVA420P10BE,
    AV_PIX_FMT_YUVA420P10LE,
    AV_PIX_FMT_YUVA422P10BE,
    AV_PIX_FMT_YUVA422P10LE,
    AV_PIX_FMT_YUVA444P10BE,
    AV_PIX_FMT_YUVA444P10LE,
    AV_PIX_FMT_YUVA420P16BE,
    AV_PIX_FMT_YUVA420P16LE,
    AV_PIX_FMT_YUVA422P16BE,
    AV_PIX_FMT_YUVA422P16LE,
    AV_PIX_FMT_YUVA444P16BE,
    AV_PIX_FMT_YUVA444P16LE,
    AV_PIX_FMT_VDPAU,
    AV_PIX_FMT_XYZ12LE,
    AV_PIX_FMT_XYZ12BE,
    AV_PIX_FMT_NV16,
    AV_PIX_FMT_NV20LE,
    AV_PIX_FMT_NV20BE,
    AV_PIX_FMT_RGBA64BE,
    AV_PIX_FMT_RGBA64LE,
    AV_PIX_FMT_BGRA64BE,
    AV_PIX_FMT_BGRA64LE,
    AV_PIX_FMT_YVYU422,
    AV_PIX_FMT_YA16BE,
    AV_PIX_FMT_YA16LE,
    AV_PIX_FMT_GBRAP,
    AV_PIX_FMT_GBRAP16BE,
    AV_PIX_FMT_GBRAP16LE,
    AV_PIX_FMT_QSV,
    AV_PIX_FMT_MMAL,
    AV_PIX_FMT_D3D11VA_VLD,
    AV_PIX_FMT_CUDA,
    AV_PIX_FMT_0RGB,
    AV_PIX_FMT_RGB0,
    AV_PIX_FMT_0BGR,
    AV_PIX_FMT_BGR0,
    AV_PIX_FMT_YUV420P12BE,
    AV_PIX_FMT_YUV420P12LE,
    AV_PIX_FMT_YUV420P14BE,
    AV_PIX_FMT_YUV420P14LE,
    AV_PIX_FMT_YUV422P12BE,
    AV_PIX_FMT_YUV422P12LE,
    AV_PIX_FMT_YUV422P14BE,
    AV_PIX_FMT_YUV422P14LE,
    AV_PIX_FMT_YUV444P12BE,
    AV_PIX_FMT_YUV444P12LE,
    AV_PIX_FMT_YUV444P14BE,
    AV_PIX_FMT_YUV444P14LE,
    AV_PIX_FMT_GBRP12BE,
    AV_PIX_FMT_GBRP12LE,
    AV_PIX_FMT_GBRP14BE,
    AV_PIX_FMT_GBRP14LE,
    AV_PIX_FMT_YUVJ411P,
    AV_PIX_FMT_BAYER_BGGR8,
    AV_PIX_FMT_BAYER_RGGB8,
    AV_PIX_FMT_BAYER_GBRG8,
    AV_PIX_FMT_BAYER_GRBG8,
    AV_PIX_FMT_BAYER_BGGR16LE,
    AV_PIX_FMT_BAYER_BGGR16BE,
    AV_PIX_FMT_BAYER_RGGB16LE,
    AV_PIX_FMT_BAYER_RGGB16BE,
    AV_PIX_FMT_BAYER_GBRG16LE,
    AV_PIX_FMT_BAYER_GBRG16BE,
    AV_PIX_FMT_BAYER_GRBG16LE,
    AV_PIX_FMT_BAYER_GRBG16BE,
    AV_PIX_FMT_XVMC,
    AV_PIX_FMT_YUV440P10LE,
    AV_PIX_FMT_YUV440P10BE,
    AV_PIX_FMT_YUV440P12LE,
    AV_PIX_FMT_YUV440P12BE,
    AV_PIX_FMT_AYUV64LE,
    AV_PIX_FMT_AYUV64BE,
    AV_PIX_FMT_VIDEOTOOLBOX,
    AV_PIX_FMT_P010LE,
    AV_PIX_FMT_P010BE,
    AV_PIX_FMT_GBRAP12BE,
    AV_PIX_FMT_GBRAP12LE,
    AV_PIX_FMT_GBRAP10BE,
    AV_PIX_FMT_GBRAP10LE,
    AV_PIX_FMT_MEDIACODEC,
    AV_PIX_FMT_GRAY12BE,
    AV_PIX_FMT_GRAY12LE,
    AV_PIX_FMT_GRAY10BE,
    AV_PIX_FMT_GRAY10LE,
    AV_PIX_FMT_P016LE,
    AV_PIX_FMT_P016BE,
    AV_PIX_FMT_D3D11,
    AV_PIX_FMT_GRAY9BE,
    AV_PIX_FMT_GRAY9LE,
    AV_PIX_FMT_GBRPF32BE,
    AV_PIX_FMT_GBRPF32LE,
    AV_PIX_FMT_GBRAPF32BE,
    AV_PIX_FMT_GBRAPF32LE,
    AV_PIX_FMT_DRM_PRIME,
    AV_PIX_FMT_OPENCL,
    AV_PIX_FMT_GRAY14BE,
    AV_PIX_FMT_GRAY14LE,
    AV_PIX_FMT_GRAYF32BE,
    AV_PIX_FMT_GRAYF32LE,
    AV_PIX_FMT_YUVA422P12BE,
    AV_PIX_FMT_YUVA422P12LE,
    AV_PIX_FMT_YUVA444P12BE,
    AV_PIX_FMT_YUVA444P12LE,
    AV_PIX_FMT_NV24,
    AV_PIX_FMT_NV42,
    AV_PIX_FMT_NB
  );

  PAVSampleFormat = ^TAVSampleFormat;
  TAVSampleFormat = (
    AV_SAMPLE_FMT_NONE = -1,
    AV_SAMPLE_FMT_U8,
    AV_SAMPLE_FMT_S16,
    AV_SAMPLE_FMT_S32,
    AV_SAMPLE_FMT_FLT,
    AV_SAMPLE_FMT_DBL,
    AV_SAMPLE_FMT_U8P,
    AV_SAMPLE_FMT_S16P,
    AV_SAMPLE_FMT_S32P,
    AV_SAMPLE_FMT_FLTP,
    AV_SAMPLE_FMT_DBLP,
    AV_SAMPLE_FMT_S64,
    AV_SAMPLE_FMT_S64P,
    AV_SAMPLE_FMT_NB
  );

  TAVOptionType = (
    AV_OPT_TYPE_FLAGS,
    AV_OPT_TYPE_INT,
    AV_OPT_TYPE_INT64,
    AV_OPT_TYPE_DOUBLE,
    AV_OPT_TYPE_FLOAT,
    AV_OPT_TYPE_STRING,
    AV_OPT_TYPE_RATIONAL,
    AV_OPT_TYPE_BINARY,
    AV_OPT_TYPE_DICT,
    AV_OPT_TYPE_UINT64,
    AV_OPT_TYPE_CONST,
    AV_OPT_TYPE_IMAGE_SIZE,
    AV_OPT_TYPE_PIXEL_FMT,
    AV_OPT_TYPE_SAMPLE_FMT,
    AV_OPT_TYPE_VIDEO_RATE,
    AV_OPT_TYPE_DURATION,
    AV_OPT_TYPE_COLOR,
    AV_OPT_TYPE_CHANNEL_LAYOUT,
    AV_OPT_TYPE_BOOL
  );

  TAVClassCategory = (
    AV_CLASS_CATEGORY_NA = 0,
    AV_CLASS_CATEGORY_INPUT,
    AV_CLASS_CATEGORY_OUTPUT,
    AV_CLASS_CATEGORY_MUXER,
    AV_CLASS_CATEGORY_DEMUXER,
    AV_CLASS_CATEGORY_ENCODER,
    AV_CLASS_CATEGORY_DECODER,
    AV_CLASS_CATEGORY_FILTER,
    AV_CLASS_CATEGORY_BITSTREAM_FILTER,
    AV_CLASS_CATEGORY_SWSCALER,
    AV_CLASS_CATEGORY_SWRESAMPLER,
    AV_CLASS_CATEGORY_DEVICE_VIDEO_OUTPUT = 40,
    AV_CLASS_CATEGORY_DEVICE_VIDEO_INPUT,
    AV_CLASS_CATEGORY_DEVICE_AUDIO_OUTPUT,
    AV_CLASS_CATEGORY_DEVICE_AUDIO_INPUT,
    AV_CLASS_CATEGORY_DEVICE_OUTPUT,
    AV_CLASS_CATEGORY_DEVICE_INPUT,
    AV_CLASS_CATEGORY_NB
  );

  TAVFieldOrder = (
    AV_FIELD_UNKNOWN,
    AV_FIELD_PROGRESSIVE,
    AV_FIELD_TT,
    AV_FIELD_BB,
    AV_FIELD_TB,
    AV_FIELD_BT
  );

  TAVAudioServiceType = (
    AV_AUDIO_SERVICE_TYPE_MAIN              = 0,
    AV_AUDIO_SERVICE_TYPE_EFFECTS           = 1,
    AV_AUDIO_SERVICE_TYPE_VISUALLY_IMPAIRED = 2,
    AV_AUDIO_SERVICE_TYPE_HEARING_IMPAIRED  = 3,
    AV_AUDIO_SERVICE_TYPE_DIALOGUE          = 4,
    AV_AUDIO_SERVICE_TYPE_COMMENTARY        = 5,
    AV_AUDIO_SERVICE_TYPE_EMERGENCY         = 6,
    AV_AUDIO_SERVICE_TYPE_VOICE_OVER        = 7,
    AV_AUDIO_SERVICE_TYPE_KARAOKE           = 8,
    AV_AUDIO_SERVICE_TYPE_NB
  );

  TAVDiscard = (
    AVDISCARD_NONE    =-16,
    AVDISCARD_DEFAULT =  0,
    AVDISCARD_NONREF  =  8,
    AVDISCARD_BIDIR   = 16,
    AVDISCARD_NONINTRA= 24,
    AVDISCARD_NONKEY  = 32,
    AVDISCARD_ALL     = 48
  );

  TAVSubtitleType = (
    SUBTITLE_NONE,
    SUBTITLE_BITMAP,
    SUBTITLE_TEXT,
    SUBTITLE_ASS
  );

  PPAVCodec = ^PAVCodec;
  PAVCodec = ^TAVCodec;
  PAVHWAccel = ^TAVHWAccel;
  PPAVCodecContext = ^PAVCodecContext;
  PAVCodecContext = ^TAVCodecContext;
  TexecuteCall = function (c2: PAVCodecContext; arg: Pointer): Integer; cdecl;
  Texecute2Call = function (c2: PAVCodecContext; arg: Pointer; jobnr, threadnr: Integer): Integer; cdecl;

  PAVBuffer = ^TAVBuffer;
  TAVBuffer = record
    // need {$ALIGN 8}
    // defined libavutil/buffer_internal.h
  end;

  PPAVBufferRef = ^PAVBufferRef;
  PAVBufferRef = ^TAVBufferRef;
  TAVBufferRef = record
    buffer: PAVBuffer;
    data: PByte;
    size: Integer;
  end;

  PAVPacketSideData = ^TAVPacketSideData;
  TAVPacketSideData = record
    data: PByte;
    size: Integer;
    type_: TAVPacketSideDataType;
  end;

  PPAVPacket = ^PAVPacket;
  PAVPacket = ^TAVPacket;
  TAVPacket = record
    buf: PAVBufferRef;
    pts: Int64;
    dts: Int64;
    data: PByte;
    size: Integer;
    stream_index: Integer;
    flags: Integer;
    side_data: PAVPacketSideData;
    side_data_elems: Integer;
    duration: Int64;
    pos: Int64;
{$IFDEF FF_API_CONVERGENCE_DURATION}
    convergence_duration: Int64;
{$ENDIF}
  end;

  PAVRational = ^TAVRational;
  TAVRational = record
    num: Integer;
    den: Integer;
  end;

  PAVDictionaryEntry = ^TAVDictionaryEntry;
  TAVDictionaryEntry = record
    key: PAnsiChar;
    value: PAnsiChar;
  end;

  PPAVDictionary = ^PAVDictionary;
  PAVDictionary = ^TAVDictionary;
  TAVDictionary = record
    // defined in libavutil/dict.h
    count: Integer;
    elems: PAVDictionaryEntry;
  end;

  PPAVFrameSideData = ^PAVFrameSideData;
  PAVFrameSideData = ^TAVFrameSideData;
  TAVFrameSideData = record
    type_: TAVFrameSideDataType;
    data: PByte;
    size: Integer;
    metadata: PAVDictionary;
    buf: PAVBufferRef;
  end;

  PPAVFrame = ^PAVFrame;
  PAVFrame = ^TAVFrame;
  TAVFrame = record
    data: array[0..AV_NUM_DATA_POINTERS-1] of PByte;
    linesize: array[0..AV_NUM_DATA_POINTERS-1] of Integer;
    extended_data: PPByte;
    width, height: Integer;
    nb_samples: Integer;
    format: Integer;
    key_frame: Integer;
    pict_type: TAVPictureType;
    sample_aspect_ratio: TAVRational;
    pts: Int64;
{$IFDEF FF_API_PKT_PTS}
    pkt_pts: Int64;
{$ENDIF}
    pkt_dts: Int64;
    coded_picture_number: Integer;
    display_picture_number: Integer;
    quality: Integer;
    opaque: Pointer;
{$IFDEF FF_API_ERROR_FRAME}
    error: array[0..AV_NUM_DATA_POINTERS-1] of Int64;
{$ENDIF}
    repeat_pict: Integer;
    interlaced_frame: Integer;
    top_field_first: Integer;
    palette_has_changed: Integer;
    reordered_opaque: Int64;
    sample_rate: Integer;
    channel_layout: Int64;
    buf: array[0..AV_NUM_DATA_POINTERS - 1] of PAVBufferRef;
    extended_buf: PPAVBufferRef;
    nb_extended_buf: Integer;
    side_data: PPAVFrameSideData;
    nb_side_data: Integer;
    flags: Integer;
    color_range: TAVColorRange;
    color_primaries: TAVColorPrimaries;
    color_trc: TAVColorTransferCharacteristic;
    colorspace: TAVColorSpace;
    chroma_location: TAVChromaLocation;
    best_effort_timestamp: Int64;
    pkt_pos: Int64;
    pkt_duration: Int64;
    metadata: PAVDictionary;
    decode_error_flags: Integer;
    channels: Integer;
    pkt_size: Integer;
{$IFDEF FF_API_FRAME_QP}
    qscale_table: PByte;
    qstride: Integer;
    qscale_type: Integer;
    qp_table_buf: PAVBufferRef;
{$ENDIF}
    hw_frames_ctx: PAVBufferRef;
    opaque_ref: PAVBufferRef;
    crop_top: Size_t;
    crop_bottom: Size_t;
    crop_left: Size_t;
    crop_right: Size_t;
    private_ref: PAVBufferRef;
  end;

  _Tdefault_val = record
    case Integer of
      0: (i64: Int64);
      1: (dbl: Double);
      2: (str: PAnsiChar);
      3: (q: TAVRational);
    end;

  PPAVOption = ^PAVOption;
  PAVOption = ^TAVOption;
  TAVOption = record
    name: PAnsiChar;
    help: PAnsiChar;
    offset: Integer;
    ttype: TAVOptionType;
    default_val: _Tdefault_val;
    min: Double;
    max: Double;
    flags: Integer;
    uunit: PAnsiChar;
  end;

  PPAVOptionRange = ^PAVOptionRange;
  PAVOptionRange = ^TAVOptionRange;
  TAVOptionRange = record
    str: PAnsiChar;
    value_min, value_max: Double;
    component_min, component_max: Double;
    is_range: Integer;
  end;

  PPAVOptionRanges = ^PAVOptionRanges;
  PAVOptionRanges = ^TAVOptionRanges;
  TAVOptionRanges = record
    range: PPAVOptionRange;
    nb_ranges: Integer;
    nb_components: Integer;
  end;

  PPPAVClass = ^PPAVClass;
  PPAVClass = ^PAVClass;
  PAVClass = ^TAVClass;
  TAVClass = record
    class_name: PAnsiChar;
    item_name: function(ctx: Pointer): PAnsiChar; cdecl;
    option: PAVOption;
    version: Integer;
    log_level_offset_offset: Integer;
    parent_log_context_offset: Integer;
    child_next: function(obj, prev: Pointer): Pointer; cdecl;
    child_class_next: function(const prev: PAVClass): PAVClass; cdecl;
    category: TAVClassCategory;
    get_category: function(ctx: Pointer): TAVClassCategory; cdecl;
    query_ranges: function(ranges: PPAVOptionRanges; obj: Pointer; const key: PAnsiChar; flags: Integer): Integer; cdecl;
  end;

  PAVProfile = ^TAVProfile;
  TAVProfile = record
    profile: Integer;
    name: PAnsiChar; ///< short name for the profile
  end;

  PAVCodecInternal = ^TAVCodecInternal;
  TAVCodecInternal = record
    // need {$ALIGN 8}
    // defined in libavcodec/internal.h
  end;

  PRcOverride = ^TRcOverride;
  TRcOverride = record // SizeOf = 16
    start_frame: Integer;
    end_frame: Integer;
    qscale: Integer; // If this is 0 then quality_factor will be used instead.
    quality_factor: Single;
  end;

  PMpegEncContext = ^TMpegEncContext;
  TMpegEncContext = record
    // need {$ALIGN 8}
    // defined in libavcodec/mpegvideo.h
  end;

  TAVHWAccel = record
    name: PAnsiChar;
    ttype: TAVMediaType;
    id: TAVCodecID;
    pix_fmt: TAVPixelFormat;
    capabilities: Integer;
    alloc_frame: function(avctx: PAVCodecContext; frame: PAVFrame): Integer; cdecl;
    start_frame: function(avctx: PAVCodecContext; const buf: PByte; buf_size: Cardinal): Integer; cdecl;
    decode_params: function(avctx: PAVCodecContext; type_: Integer; const buf: PByte; buf_size: Cardinal): Integer; cdecl;
    decode_slice: function(avctx: PAVCodecContext; const buf: PByte; buf_size: Cardinal): Integer; cdecl;
    end_frame: function(avctx: PAVCodecContext): Integer; cdecl;
    frame_priv_data_size: Integer;
    decode_mb: procedure(s: PMpegEncContext); cdecl;
    init: function(avctx: PAVCodecContext): Integer; cdecl;
    uninit: function(avctx: PAVCodecContext): Integer; cdecl;
    priv_data_size: Integer;
    caps_internal: Integer;
    frame_params: function(avctx: PAVCodecContext; hw_frames_ctx: PAVBufferRef): Integer; cdecl;
  end;

  PAVCodecDescriptor = ^TAVCodecDescriptor;
  TAVCodecDescriptor = record
    id: TAVCodecID;
    ttype: TAVMediaType;
    name: PAnsiChar;
    long_name: PAnsiChar;
    props: Integer;
    mime_types: PPAnsiChar;
    profiles: PAVProfile;
  end;

  TAVCodecContext = record
    av_class: PAVClass;
    log_level_offset: Integer;
    codec_type: TAVMediaType;
    codec: PAVCodec;
    codec_id: TAVCodecID;
    codec_tag: packed record
      case Integer of
        0: (tag: Cardinal);
        1: (fourcc: array[0..3] of AnsiChar);
        2: (fourbb: array[0..3] of Byte);
      end;
    priv_data: Pointer;
    internal: PAVCodecInternal;
    opaque: Pointer;
    bit_rate: Int64;
    bit_rate_tolerance: Integer;
    global_quality: Integer;
    compression_level: Integer;
    flags: Integer;
    flags2: Integer;
    extradata: PByte;
    extradata_size: Integer;
    time_base: TAVRational;
    ticks_per_frame: Integer;
    delay: Integer;
    width, height: Integer;
    coded_width, coded_height: Integer;
    gop_size: Integer;
    pix_fmt: TAVPixelFormat;
    draw_horiz_band: procedure (s: PAVCodecContext;
                            const src: PAVFrame; offset: PInteger;
                            y, ttype, height: Integer); cdecl;
    get_format: function(s: PAVCodecContext; const fmt: PAVPixelFormat): TAVPixelFormat; cdecl;
    max_b_frames: Integer;
    b_quant_factor: Single;
{$IFDEF FF_API_PRIVATE_OPT}
    b_frame_strategy: Integer;
{$ENDIF}
    b_quant_offset: Single;
    has_b_frames: Integer;
{$IFDEF FF_API_PRIVATE_OPT}
    mpeg_quant: Integer;
{$ENDIF}
    i_quant_factor: Single;
    i_quant_offset: Single;
    lumi_masking: Single;
    temporal_cplx_masking: Single;
    spatial_cplx_masking: Single;
    p_masking: Single;
    dark_masking: Single;
    slice_count: Integer;
{$IFDEF FF_API_PRIVATE_OPT}
    prediction_method: Integer;
{$ENDIF}
    slice_offset: PInteger;
    sample_aspect_ratio: TAVRational;
    me_cmp: Integer;
    me_sub_cmp: Integer;
    mb_cmp: Integer;
    ildct_cmp: Integer;
    dia_size: Integer;
    last_predictor_count: Integer;
{$IFDEF FF_API_PRIVATE_OPT}
    pre_me: Integer;
{$ENDIF}
    me_pre_cmp: Integer;
    pre_dia_size: Integer;
    me_subpel_quality: Integer;
    me_range: Integer;
    slice_flags: Integer;
    mb_decision: Integer;
    intra_matrix: PWord;
    inter_matrix: PWord;
{$IFDEF FF_API_PRIVATE_OPT}
    scenechange_threshold: Integer;
    noise_reduction: Integer;
{$ENDIF}
    intra_dc_precision: Integer;
    skip_top: Integer;
    skip_bottom: Integer;
    mb_lmin: Integer;
    mb_lmax: Integer;
{$IFDEF FF_API_PRIVATE_OPT}
    me_penalty_compensation: Integer;
{$ENDIF}
    bidir_refine: Integer;
{$IFDEF FF_API_PRIVATE_OPT}
    brd_scale: Integer;
{$ENDIF}
    keyint_min: Integer;
    refs: Integer;
{$IFDEF FF_API_PRIVATE_OPT}
    chromaoffset: Integer;
{$ENDIF}
    mv0_threshold: Integer;
{$IFDEF FF_API_PRIVATE_OPT}
    b_sensitivity: Integer;
{$ENDIF}
    color_primaries: TAVColorPrimaries;
    color_trc: TAVColorTransferCharacteristic;
    colorspace: TAVColorSpace;
    color_range: TAVColorRange;
    chroma_sample_location: TAVChromaLocation;
    slices: Integer;
    field_order: TAVFieldOrder;
    sample_rate: Integer;
    channels: Integer;
    sample_fmt: TAVSampleFormat;
    frame_size: Integer;
    frame_number: Integer;
    block_align: Integer;
    cutoff: Integer;
    channel_layout: Int64;
    request_channel_layout: Int64;
     audio_service_type: TAVAudioServiceType;
    request_sample_fmt: TAVSampleFormat;
    get_buffer2: function(s: PAVCodecContext; frame: PAVFrame; flags: Integer): Integer; cdecl;
    refcounted_frames: Integer;
    qcompress: Single;
    qblur: Single;
    qmin: Integer;
    qmax: Integer;
    max_qdiff: Integer;
    rc_buffer_size: Integer;
    rc_override_count: Integer;
    rc_override: PRcOverride;
    rc_max_rate: Int64;
    rc_min_rate: Int64;
    rc_max_available_vbv_use: Single;
    rc_min_vbv_overflow_use: Single;
    rc_initial_buffer_occupancy: Integer;
{$IFDEF FF_API_CODER_TYPE}
    coder_type: Integer;
{$ENDIF}
{$IFDEF FF_API_PRIVATE_OPT}
    context_model: Integer;
{$ENDIF}
{$IFDEF FF_API_PRIVATE_OPT}
    frame_skip_threshold: Integer;
    frame_skip_factor: Integer;
    frame_skip_exp: Integer;
    frame_skip_cmp: Integer;
{$ENDIF}
    trellis: Integer;
{$IFDEF FF_API_PRIVATE_OPT}
    min_prediction_order: Integer;
    max_prediction_order: Integer;
    timecode_frame_start: Int64;
{$ENDIF}
{$IFDEF FF_API_RTP_CALLBACK}
    rtp_callback: procedure(avctx: PAVCodecContext; data: Pointer; size, mb_nb: Integer);
{$ENDIF}
{$IFDEF FF_API_PRIVATE_OPT}
    rtp_payload_size: Integer;
{$ENDIF}
{$IFDEF FF_API_STAT_BITS}
    mv_bits: Integer;
    header_bits: Integer;
    i_tex_bits: Integer;
    p_tex_bits: Integer;
    i_count: Integer;
    p_count: Integer;
    skip_count: Integer;
    misc_bits: Integer;
    frame_bits: Integer;
{$ENDIF}
    stats_out: PAnsiChar;
    stats_in: PAnsiChar;
    workaround_bugs: Integer;
    strict_std_compliance: Integer;
    error_concealment: Integer;
    debug: Integer;
{$IFDEF FF_API_DEBUG_MV}
    debug_mv: Integer;
{$ENDIF}
    err_recognition: Integer;
    reordered_opaque: Int64;
    hwaccel: PAVHWAccel;
    hwaccel_context: Pointer;
    error: array[0..AV_NUM_DATA_POINTERS-1] of Int64;
    dct_algo: Integer;
    idct_algo: Integer;
    bits_per_coded_sample: Integer;
    bits_per_raw_sample: Integer;
{$IFDEF FF_API_LOWRES}
     lowres: Integer;
{$ENDIF}
{$IFDEF FF_API_CODED_FRAME}
    coded_frame: PAVFrame;
{$ENDIF}
    thread_count: Integer;
    thread_type: Integer;
    active_thread_type: Integer;
    thread_safe_callbacks: Integer;
    execute: function (c: PAVCodecContext; func: TexecuteCall; arg2: Pointer; ret: PInteger; count, size: Integer): Integer; cdecl;
    execute2: function (c: PAVCodecContext; func: Texecute2Call; arg2: Pointer; ret: PInteger; count: Integer): Integer; cdecl;
     nsse_weight: Integer;
     profile: Integer;
     level: Integer;
    skip_loop_filter: TAVDiscard;
    skip_idct: TAVDiscard;
    skip_frame: TAVDiscard;
    subtitle_header: PByte;
    subtitle_header_size: Integer;
{$IFDEF FF_API_VBV_DELAY}
    vbv_delay: Int64;
{$ENDIF}
{$IFDEF FF_API_SIDEDATA_ONLY_PKT}
    side_data_only_packets: Integer;
{$ENDIF}
    initial_padding: Integer;
    framerate: TAVRational;
    sw_pix_fmt: TAVPixelFormat;
    pkt_timebase: TAVRational;
    codec_descriptor: PAVCodecDescriptor;
{$IFNDEF FF_API_LOWRES}
    lowres: Integer;
{$ENDIF}
    pts_correction_num_faulty_pts: Int64;
    pts_correction_num_faulty_dts: Int64;
    pts_correction_last_pts: Int64;
    pts_correction_last_dts: Int64;
    sub_charenc: PAnsiChar;
    sub_charenc_mode: Integer;
    skip_alpha: Integer;
    seek_preroll: Integer;
{$IFNDEF FF_API_DEBUG_MV}
    debug_mv: Integer;
{$ENDIF}
    chroma_intra_matrix: PWord;
    dump_separator: PByte;
    codec_whitelist: PAnsiChar;
    properties: Cardinal;
    coded_side_data: PAVPacketSideData;
    nb_coded_side_data: Integer;
    hw_frames_ctx: PAVBufferRef;
    sub_text_format: Integer;
    trailing_padding: Integer;
    max_pixels: Int64;
    hw_device_ctx: PAVBufferRef;
    hwaccel_flags: Integer;
    apply_cropping: Integer;
    extra_hw_frames: Integer;
    discard_damaged_percentage: Integer;
  end;

  PAVCodecDefault = ^TAVCodecDefault;
  TAVCodecDefault = record
    // need {$ALIGN 8}
    // defined in libavcodec/internal.h
  end;

  PPAVSubtitleRect = ^PAVSubtitleRect;
  PAVSubtitleRect = ^TAVSubtitleRect;
  TAVSubtitleRect = record
    x: Integer;
    y: Integer;
    w: Integer;
    h: Integer;
    nb_colors: Integer;
{$IFDEF FF_API_AVPICTURE}
    pict: TAVPicture;
{$ENDIF}
    data: array[0..3] of PByte;
    linesize: array[0..3] of Integer;
    ttype: TAVSubtitleType;
    text: PAnsiChar;
    ass: PAnsiChar;
    flags: Integer;
  end;

  PAVSubtitle = ^TAVSubtitle;
  TAVSubtitle = record
    format: Word; (* 0 = graphics *)
    start_display_time: Cardinal; (* relative to packet pts, in ms *)
    end_display_time: Cardinal; (* relative to packet pts, in ms *)
    num_rects: Cardinal;
    rects: PPAVSubtitleRect;
    pts: Int64;    ///< Same as packet pts, in AV_TIME_BASE
  end;

  PPAVCodecHWConfigInternal = ^PAVCodecHWConfigInternal;
  PAVCodecHWConfigInternal = ^TAVCodecHWConfigInternal;
  TAVCodecHWConfigInternal = record
    // need {$ALIGN 8}
    // defined in libavcodec/hwaccel.h
  end;

  TAVCodec = record
    name: PAnsiChar;
    long_name: PAnsiChar;
    ttype: TAVMediaType;
    id: TAVCodecID;
    capabilities: Integer;
    supported_framerates: PAVRational;
    pix_fmts: PAVPixelFormat;
    supported_samplerates: PInteger;
    sample_fmts: PAVSampleFormat;
    channel_layouts: PInt64;
    max_lowres: Byte;
    priv_class: PAVClass;
    profiles: PAVProfile;
    wrapper_name: PAnsiChar;
    priv_data_size: Integer;
    next: PAVCodec;
    init_thread_copy: function(ctx: PAVCodecContext): Integer; cdecl;
    update_thread_context: function(dst, src: PAVCodecContext): Integer; cdecl;
    defaults: PAVCodecDefault;
    init_static_data: function(codec: PAVCodec): Pointer; cdecl;
    init: function(avctx: PAVCodecContext): Integer; cdecl;
    encode_sub: function(avctx: PAVCodecContext; buf: PByte; buf_size: Integer;
                      const sub: PAVSubtitle): Integer; cdecl;
    encode2: function(avctx: PAVCodecContext; avpkt: PAVPacket; const frame: PAVFrame;
                      got_packet_ptr: PInteger): Integer; cdecl;
    decode: function(avcctx: PAVCodecContext; outdata: Pointer; outdata_size: PInteger; avpkt: PAVPacket): Integer; cdecl;
    close: function(avcctx: PAVCodecContext): Integer; cdecl;
    send_frame: function(avctx: PAVCodecContext; const frame: PAVFrame): Integer; cdecl;
    receive_packet: function(avctx: PAVCodecContext; avpkt: PAVPacket): Integer; cdecl;
    receive_frame: function(avctx: PAVCodecContext; frame: PAVFrame): Integer; cdecl;
    flush: procedure(avcctx: PAVCodecContext); cdecl;
    caps_internal: Integer;
    bsfs: PAnsiChar;
    hw_configs: PPAVCodecHWConfigInternal;
  end;

  PAVPicture = ^TAVPicture;
  TAVPicture = record
    data: array[0..AV_NUM_DATA_POINTERS-1] of PByte;        ///< pointers to the image data planes
    linesize: array[0..AV_NUM_DATA_POINTERS-1] of Integer;  ///< number of bytes per line
  end;

  PPSwsContext = ^PSwsContext;
  PSwsContext = ^TSwsContext;
  TSwsContext = record
    // need {$ALIGN 8}
    // defined in libswscale/swscale_internal.h
  end;

  PSwsVector = ^TSwsVector;
  TSwsVector = record
    coeff: PDouble;             ///< pointer to the list of coefficients
    length: Integer;            ///< number of coefficients in the vector
  end;

  PSwsFilter = ^TSwsFilter;
  TSwsFilter = record
    lumH: PSwsVector;
    lumV: PSwsVector;
    chrH: PSwsVector;
    chrV: PSwsVector;
  end;

function av_packet_alloc: PAVPacket; cdecl; external AVCODEC_LIBNAME name 'av_packet_alloc';
procedure av_packet_free(pkt: PPAVPacket); cdecl; external AVCODEC_LIBNAME name 'av_packet_free';
function avcodec_alloc_context3(const codec: PAVCodec): PAVCodecContext; cdecl; external AVCODEC_LIBNAME name
    'avcodec_alloc_context3';
function avcodec_close(avctx: PAVCodecContext): Integer; cdecl; external AVCODEC_LIBNAME name 'avcodec_close';
function avcodec_decode_video2(avctx: PAVCodecContext; picture: PAVFrame; got_picture_ptr: PInteger;
    const avpkt: PAVPacket): Integer; cdecl; external AVCODEC_LIBNAME name 'avcodec_decode_video2';
procedure avcodec_free_context(avctx: PPAVCodecContext); cdecl; external AVCODEC_LIBNAME name 'avcodec_free_context';
function avcodec_find_decoder(id: TAVCodecID): PAVCodec; cdecl; external AVCODEC_LIBNAME name 'avcodec_find_decoder';
function avcodec_open2(avctx: PAVCodecContext; const codec: PAVCodec; options: PPAVDictionary): Integer; cdecl;
    external AVCODEC_LIBNAME name 'avcodec_open2';
function avpicture_alloc(picture: PAVPicture; pix_fmt: TAVPixelFormat; width, height: Integer): Integer; cdecl;
    external AVCODEC_LIBNAME name 'avpicture_alloc';

function av_frame_alloc: PAVFrame; cdecl; external AVUTIL_LIBNAME name 'av_frame_alloc';
procedure av_frame_free(frame: PPAVFrame); cdecl; external AVUTIL_LIBNAME name 'av_frame_free';

function sws_getContext(srcW, srcH: Integer; srcFormat: TAVPixelFormat; dstW, dstH: Integer; dstFormat: TAVPixelFormat;
    flags: Integer; srcFilter, dstFilter: PSwsFilter; param: PDouble): PSwsContext; cdecl; external SWSCALE_LIBNAME
    name 'sws_getContext';
function sws_scale(c: PSwsContext; const srcSlice: PPByte; const srcStride: PInteger; srcSliceY, srcSliceH: Integer;
    const dst: PPByte; const dstStride: PInteger): Integer; cdecl; external SWSCALE_LIBNAME name 'sws_scale';

implementation

end.
