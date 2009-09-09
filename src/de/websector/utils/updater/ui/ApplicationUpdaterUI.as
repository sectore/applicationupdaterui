package de.websector.utils.updater.ui
{
		import de.websector.utils.updater.ui.skins.standard.AppUpdaterUIStandardSkin;
		
		import air.update.ApplicationUpdater;
		import air.update.events.DownloadErrorEvent;
		import air.update.events.StatusFileUpdateErrorEvent;
		import air.update.events.StatusUpdateErrorEvent;
		import air.update.events.StatusUpdateEvent;
		import air.update.events.UpdateEvent;
		
		import flash.desktop.NativeApplication;
		import flash.events.ErrorEvent;
		import flash.events.MouseEvent;
		import flash.events.ProgressEvent;
		import flash.filesystem.File;
		
		import mx.controls.ProgressBar;
		
		import spark.components.Button;
		import spark.components.SkinnableContainer;
		import spark.components.Window;
		import spark.components.supportClasses.TextBase;
		import com.adobe.utils.LocaleUtil;
		
		[SkinState("checkForUpdate")]
		[SkinState("updateAvailable")]
		[SkinState("noUpdateAvailable")]
		[SkinState("downloadProgress")]
		
		[SkinState("installUpdate")]
		
		[SkinState("updateError")]
		[SkinState("unexpectedError")]
		[SkinState("downloadError")]
		[SkinState("fileError")]
		
		public class ApplicationUpdaterUI extends SkinnableContainer
		{	
			//
			// vars
			protected var window: Window;
			
			protected var _invisibleCheck: Boolean = true;
			protected var invisibleCheckChanged: Boolean = false;
			
			protected var _useWindow: Boolean = false;
			protected var isInstallPostponed: Boolean = false;
			
			
			
			protected var initializeAppUpdaterAndCheckNow: Boolean = false;
			protected var appUpdaterInitialized: Boolean = false;
			
			
			public var windowWidth: int = 200;
			public var windowHeight: int = 200;
			
			[Bindable]
			public var errorID: String = '';
			
			[Bindable]
			public var appName: String = '';

			[Bindable]
			public var updateDescription: String = '';
			
			[Bindable]
			public var installedVersion: String = '';
			
			[Bindable]
			public var updateVersion: String = '';
			
			protected var currentSkinState: String = STATE_CHECK_FOR_UPDATE;
			
			//
			// const
			protected static const VERSION: String = "0.2";	
			
			protected static const STATE_CHECK_FOR_UPDATE: String 		= "checkForUpdate";
			protected static const STATE_UPDATE_AVAILABLE: String 		= "updateAvailable";
			protected static const STATE_UPDATE_NOT_AVAILABLE: String 	= "noUpdateAvailable";
			protected static const STATE_DOWNLOAD_PROGRESS: String 		= "downloadProgress";
			
			protected static const STATE_INSTALL_UPDATE: String 		= "installUpdate";
			
			protected static const STATE_UPDATE_ERROR: String 			= "updateError";
			protected static const STATE_UNEXPECTED_ERROR: String 		= "unexpectedError";
			protected static const STATE_DOWNLOAD_ERROR: String 		= "downloadError";
			protected static const STATE_FILE_ERROR: String 			= "fileError";
			
			
			//
			// instances
			protected var appUpdater: ApplicationUpdater;
			protected var _configurationFile: File;
			
			
			//
			// skin parts
			
			[SkinPart(required="false")]
			public var displayLabel: TextBase;
			
			[SkinPart(required="false")]
			public var infoText: TextBase;
			
			[SkinPart(required="true")]
			public var button0: Button;
			
			[SkinPart(required="true")]
			public var button1: Button;
			
			[SkinPart(required="false")]
			public var progressBar: ProgressBar;
			
			
			/**
			 * A custom updater ui for air applications using Adobes AIR update framework.
			 * It handles custom windows and views. The views can be embedded directly within the application without the needs of extra windows.
			 * 
			 */	
			public function ApplicationUpdaterUI( 	configurationFile: File = null,
													invisibleCheck: Boolean = false, 
													useWindow: Boolean = true 
												)
			{
				
				super();
				
				this.configurationFile = configurationFile;
				this.invisibleCheck = invisibleCheck;
				this.useWindow = useWindow;
				
				//
				// default skin class
				if( getStyle('skinClass') == undefined )
					setStyle("skinClass", AppUpdaterUIStandardSkin);
				
			}
			
			
			override protected function commitProperties():void
			{		
				if ( invisibleCheckChanged )
				{
					if ( invisibleCheck )
						hide( false ); // dont stop update process of appUpdater
					else
						show();
					
					invisibleCheckChanged = false;
				}
				
				
				
				super.commitProperties();
			}
			
			
			protected function initUpdater():void
			{
				
				appUpdater = new ApplicationUpdater();
				appUpdater.configurationFile = configurationFile;
				
				appUpdater.addEventListener( UpdateEvent.INITIALIZED, updaterInitializedHandler );
				
				appUpdater.addEventListener( StatusUpdateEvent.UPDATE_STATUS, updaterStatusHandler );
				
				appUpdater.addEventListener( UpdateEvent.DOWNLOAD_START, updaterDownloadStartHandler );
				appUpdater.addEventListener( ProgressEvent.PROGRESS, updaterDownloadProgressHandler );	
				appUpdater.addEventListener( UpdateEvent.DOWNLOAD_COMPLETE, updaterDownloadCompleteHandler );			
				
				appUpdater.addEventListener( UpdateEvent.BEFORE_INSTALL, updaterBeforeInstallHandler );			
				
				appUpdater.addEventListener( ErrorEvent.ERROR, updaterErrorHandler );
				appUpdater.addEventListener( DownloadErrorEvent.DOWNLOAD_ERROR, updaterErrorHandler );
				appUpdater.addEventListener( StatusUpdateErrorEvent.UPDATE_ERROR, updaterErrorHandler );			
				
				//
				// TODO: handling updates using files
				/*			appUpdater.addEventListener( StatusFileUpdateErrorEvent.FILE_UPDATE_ERROR, updaterErrorHandler );
				appUpdater.addEventListener( StatusFileUpdateEvent.FILE_UPDATE_STATUS, fileUpdaterStatusHandler );*/
				
				appUpdater.initialize();
				
			}	
			
			protected function disposeUpdater():void
			{
				if ( appUpdater )
				{
					appUpdater.configurationFile = configurationFile;
					
					appUpdater.removeEventListener( UpdateEvent.INITIALIZED, updaterInitializedHandler );
					
					appUpdater.removeEventListener( StatusUpdateEvent.UPDATE_STATUS, updaterStatusHandler  );
					
					appUpdater.removeEventListener( UpdateEvent.DOWNLOAD_START, updaterDownloadStartHandler  );
					appUpdater.removeEventListener( ProgressEvent.PROGRESS, updaterDownloadProgressHandler  );	
					appUpdater.removeEventListener( UpdateEvent.DOWNLOAD_COMPLETE, updaterDownloadCompleteHandler  );			
					
					appUpdater.removeEventListener( UpdateEvent.BEFORE_INSTALL, updaterBeforeInstallHandler );			
					
					appUpdater.removeEventListener( ErrorEvent.ERROR, updaterErrorHandler );
					appUpdater.removeEventListener( DownloadErrorEvent.DOWNLOAD_ERROR, updaterErrorHandler );
					appUpdater.removeEventListener( StatusUpdateErrorEvent.UPDATE_ERROR, updaterErrorHandler );			
					
					appUpdaterInitialized = false;
					appUpdater = null;
					
				}
				
			}	
			
			
			
			
			//--------------------------------------------------------------------------
			//
			// life cycle
			//
			//--------------------------------------------------------------------------
			
			
			
			
			override protected function partAdded(partName:String, instance:Object):void
			{
				super.partAdded(partName, instance);
				
				if (instance == button0 )
				{
					button0.addEventListener( MouseEvent.CLICK, button0ClickHandler );
				}
				if (instance == button1 )
				{
					button1.addEventListener( MouseEvent.CLICK, button1ClickHandler );
				}
			}
			
			
			
			override protected function partRemoved(partName:String, instance:Object):void
			{
				
				if (instance == button0 )
				{
					button0.removeEventListener( MouseEvent.CLICK, button0ClickHandler );			
				}
				else if (instance == button1 )
				{
					button1.removeEventListener( MouseEvent.CLICK, button1ClickHandler );			
				}
				
				super.partRemoved(partName, instance);
			}
			
			
			override protected function getCurrentSkinState():String
			{
				return currentSkinState;
			}
			
			protected function setCurrentSkinState( newState: String ):void
			{
				currentSkinState = newState;
				
				invalidateSkinState();
				
			}
			
			protected function button0ClickHandler( event: MouseEvent ):void
			{
				switch( currentSkinState )
				{
					case STATE_CHECK_FOR_UPDATE:
						// check now
						appUpdater.checkNow();
						break;
					
					case STATE_UPDATE_AVAILABLE:
						// hide to download later
						hide();
						break;				
					
					case STATE_INSTALL_UPDATE:
						// install now
						isInstallPostponed = false;
						appUpdater.installUpdate();
						break;
					
					default:
						
						
				}
			}
			
			protected function button1ClickHandler( event: MouseEvent ):void
			{
				
				switch( currentSkinState )
				{
					case STATE_CHECK_FOR_UPDATE:
						// cancel
						hide();
						break;
					case STATE_UPDATE_NOT_AVAILABLE:
						// close
						hide();	
						break;	
					case STATE_UPDATE_AVAILABLE:
						// download now
						appUpdater.downloadUpdate();	
						break;
					case STATE_DOWNLOAD_PROGRESS:
						// close
						hide();
						break;
					
					case STATE_INSTALL_UPDATE:
						// install later
						isInstallPostponed = true;
						appUpdater.installUpdate();						
						hide( false );
						break;
					
					case STATE_UPDATE_ERROR:
					case STATE_FILE_ERROR:
					case STATE_UNEXPECTED_ERROR:
					case STATE_DOWNLOAD_ERROR:
						// close
						hide();	
						break;
					
					default:				
						// close
						hide();	
						
				}
			}
			
			
			//--------------------------------------------------------------------------
			//
			// update handling
			//
			//--------------------------------------------------------------------------			
			
			public function checkNow():void
			{
				//
				// check only if the updater is initialized
				if ( appUpdaterInitialized )
				{
					isInstallPostponed = false;
					
					//
					// show check now state or do invisible check
					if ( !invisibleCheck )
					{
						show();
						setCurrentSkinState( STATE_CHECK_FOR_UPDATE );
					}
					else
					{
						appUpdater.checkNow();
					}
				}		
				else
				{			
					initializeAppUpdaterAndCheckNow = true;
				}
				
			}		
			
			
			
			protected function updaterErrorHandler( event: Event ):void
			{
				
				var errorState: String;
				
				switch( event.type )
				{
					case ErrorEvent.ERROR:
						errorID =  ErrorEvent( event ).errorID.toString();
						errorState = STATE_UNEXPECTED_ERROR;
						break;
					case StatusFileUpdateErrorEvent.FILE_UPDATE_ERROR:
						errorID = StatusFileUpdateErrorEvent( event ).errorID.toString();
						errorState = STATE_FILE_ERROR;
						
						break;
					case DownloadErrorEvent.DOWNLOAD_ERROR:
						errorID = DownloadErrorEvent( event ).errorID.toString();
						errorState = STATE_DOWNLOAD_ERROR;
						
						break;
					case StatusUpdateErrorEvent.UPDATE_ERROR:
						errorID = StatusUpdateErrorEvent( event ).errorID.toString();
						errorState = STATE_UPDATE_ERROR;
						
						break;
					default:
						errorID = "";
						errorState = STATE_UNEXPECTED_ERROR;
						
						
				}		
				
				
				if ( !invisibleCheck )
					show();
				
				setCurrentSkinState( errorState );
				
				
			}
			
			
			protected function updaterInitializedHandler( event: UpdateEvent ):void
			{
				appUpdaterInitialized = true;
				
				if ( initializeAppUpdaterAndCheckNow )
					checkNow();
				
			}	
			
			
			protected function updaterStatusHandler( event : StatusUpdateEvent ):void
			{			
				if ( event.available )
				{
					//
					// avoid auto download
					// because ( appUpdater.isDownloadUpdateVisible ) doesn't work
					event.preventDefault();				
					
					show();
					
					appName = getApplicationName() || getApplicationName();
					installedVersion = getApplicationVersion();
					updateVersion = event.version;
					
					updateDescription = getUpdateDescription( event.details );
					
					
					setCurrentSkinState( STATE_UPDATE_AVAILABLE );
				}
				else 
				{
					if ( !invisibleCheck )
					{
						show();
						setCurrentSkinState( STATE_UPDATE_NOT_AVAILABLE );
					}
					
					
				}
			}
			
			protected function updaterDownloadProgressHandler( event: ProgressEvent ):void 
			{
				setCurrentSkinState( STATE_DOWNLOAD_PROGRESS );
				
				if ( progressBar != null )
				{
					progressBar.setProgress( event.bytesLoaded, event.bytesTotal );
				}
			}
			
			protected function updaterDownloadStartHandler( event: UpdateEvent ):void 
			{
				setCurrentSkinState( STATE_DOWNLOAD_PROGRESS );
				
			}
			
			protected function updaterDownloadCompleteHandler( event: UpdateEvent ):void 
			{
				//
				// avoid auto install
				// because ( appUpdater.isInstallUpdateVisible ) doesn't work
				event.preventDefault();	
				
				
				setCurrentSkinState( STATE_INSTALL_UPDATE );
			}
			
			
			protected function updaterBeforeInstallHandler( event: UpdateEvent ):void 
			{
				if ( isInstallPostponed ) 
				{
					event.preventDefault();
					isInstallPostponed = false;
				}
				
			}
			
			
			
			
			//--------------------------------------------------------------------------
			//
			// view / window handling
			//
			//--------------------------------------------------------------------------	
			
			
			protected function show():void
			{
				if ( useWindow )
				{	
					if ( !window )
						createWindow();
				}
				else
				{
					this.visible = this.includeInLayout = true;
				}
				
				
			}
			
			protected function hide( cancelUpdate: Boolean = true ):void
			{
				if ( !isInstallPostponed && cancelUpdate ) 
					appUpdater.cancelUpdate();
				
				
				if ( useWindow )
					destroyWindow();
				else
					this.visible = this.includeInLayout = false;
			}
			
			
			protected function createWindow():void
			{
				
				destroyWindow();
				
				
				window = new Window();
				window.title = "Updating: " + getApplicationFileName();
				window.width = windowWidth; 
				window.height = windowHeight; 
				
				this.percentHeight = windowHeight;
				this.percentWidth = windowWidth;
				window.addElement( this );
				
				window.alwaysInFront = true;
				window.open();
				
			}
			
			
			protected function destroyWindow():void
			{
				if ( window != null )
				{
					window.removeElement( this );
					window.close();
					window = null;
				}
			}
			
			
			
			protected function dispose():void
			{
				hide();
				
				disposeUpdater();
			}
			
			
			
			
			//--------------------------------------------------------------------------
			//
			// getter / setter
			//
			//--------------------------------------------------------------------------			
			
			
			
			
			public function get configurationFile():File
			{
				return _configurationFile;
			}
			
			public function set configurationFile(value:File):void
			{
				if ( value == null )
					return;
				
				_configurationFile = value;	
				//
				// we do need an updater right now
				if ( !appUpdater )
					initUpdater();
			}
			
			public function get useWindow():Boolean
			{
				return _useWindow;
			}
			
			public function set useWindow(value:Boolean):void
			{
				_useWindow = value;
				
			}
			
			public function get invisibleCheck():Boolean
			{
				return _invisibleCheck;
			}
			
			public function set invisibleCheck(value:Boolean):void
			{
				if ( value !== _invisibleCheck )
				{
					_invisibleCheck = value;
					invisibleCheckChanged = true;
					
					invalidateProperties();
				}
			}
			
			
			/**
			 * Getter method to get the version of the application
			 * @return 	String	Version of application
			 * 
			 */		
			private function getApplicationVersion():String
			{
				var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
				var ns:Namespace = appXML.namespace();
				return appXML.ns::version; 
			}
			
			
			/**
			 * Getter method to get the name of the application file
			 * 
			 * @return 	String	name of application
			 * 
			 */		
			private function getApplicationFileName():String
			{
				var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
				var ns:Namespace = appXML.namespace();
				return appXML.ns::filename; 
				
			}
			
			
			/**
			 * Getter method to get the name of the application 
			 * Based on a method from Adobes ApplicationUpdaterDialogs.mxml, which is part of Adobes AIR Updater Framework
			 * 
			 * @return 	String	name of application
			 * 
			 */		
			private function getApplicationName():String
			{
				var applicationName: String;
				var xmlNS:Namespace = new Namespace("http://www.w3.org/XML/1998/namespace");
				var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
				var ns:Namespace = appXML.namespace();
				// filename is mandatory
				var elem:XMLList = appXML.ns::filename;
				// use name is if it exists in the application descriptor
				if ((appXML.ns::name).length() != 0)
				{
					elem = appXML.ns::name;
				}
				// See if element contains simple content
				if (elem.hasSimpleContent())
				{
					applicationName = elem.toString();
				}
				else
				{
					// Gather all the languages from the text children
					var elemChildren:XMLList = elem.ns::text;
					var langArray:Array = new Array();
					for each (var child:XML in elemChildren)
					{
						langArray.push(child.@xmlNS::lang.toString());
					}	
					
					// Sort the languages
					langArray = LocaleUtil.sortLanguagesByPreference(langArray, resourceManager.localeChain, "", false);
					
					// Retrieve the text child that matches the first element in
					// the language array, or the first text child if language
					// array is empty.
					if (langArray.length > 0)
					{
						var defaultLang:String = langArray[0];
						var qName:QName = new QName( xmlNS, "lang" );
						var langs:XMLList = elemChildren.( attribute( qName ) == defaultLang ); 
						applicationName = langs[0].toString();
					}
					else if (elemChildren.length() > 0)
					{
						applicationName = elemChildren[0].toString();
					}
				}
				return applicationName;
			}

			
			
			/**
			 * Helper method to get release notes
			 * Based on a method from Adobes ApplicationUpdaterDialogs.mxml, which is part of Adobes AIR Updater Framework
			 *  
			 * @param 	detail		Array of details
			 * @return 	String		Release notes depending on locale chain
			 * 
			 */			
			protected function getUpdateDescription( details: Array ):String
			{
				var text:String = "";
				
				if (details.length == 1)
				{
					text = details[0][1];
				} 
				else if (details.length > 1) 
				{
					var lang:Array = [];
					var description:Object = {};
					for(var i:int = 0; i < details.length; i++)
					{
						lang.push(details[i][0]);
						description[details[i][0]] = details[i][1];
					}
					// try to match descriptor to localeChain
					var sorted:Array = LocaleUtil.sortLanguagesByPreference(lang, resourceManager.localeChain, details[0][0], false);
					text = description[sorted[0]];
				}
				
				return text;
			}
			
		}
}