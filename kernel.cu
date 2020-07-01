#include <stdio.h>
#include <iostream> 
#include <string> 
using namespace std;
#include<cstdlib>
#include <cuda.h>
#include<string>
#include <cuda_runtime.h>
#include <math.h>
#include <SDL.h>
#include <SDL_image.h>
#undef main



__global__ void next_species(int* galive, int* ggalive, int* gage,int n) {
    int id = blockIdx.x * blockDim.x + threadIdx.x;
    int count = 0;
    if (galive[(id - 1)%n] % 2 != 0)   count += 1; //left
    if (galive[(id + 1) % n] % 2 != 0)   count += 1; //right
    if (galive[(id + blockDim.x) % n] % 2 != 0)   count += 1; //down
    if (galive[(id - blockDim.x) % n] % 2 != 0)   count += 1; //up
    if (galive[(id + blockDim.x-1) % n] % 2 != 0)   count += 1; //down left
    if (galive[(id - blockDim.x-1) % n] % 2 != 0)   count += 1; //up left
    if (galive[(id + blockDim.x+1) % n] % 2 != 0)   count += 1; //down right
    if (galive[(id - blockDim.x+1) % n] % 2 != 0)   count += 1; //up right
    //printf("%d--%d--%d\n", id, count, galive[id]);

    if (galive[id] % 2 != 0) {
        if (count != 2 && count != 3) {
            ggalive[id] = 0;
        }
        else {
            if (gage[id * 3] != 255 || gage[id * 3 + 1] != 0 || gage[id * 3 + 2] != 0) {
                
                if (gage[id * 3] != 0 && gage[id * 3 + 1] == 255 && gage[id * 3 + 2] == 0)   gage[id * 3] -= 51;
                else if (gage[id * 3] == 0 && gage[id * 3 + 1] == 255 && gage[id * 3 + 2] != 255)   gage[id * 3+2] += 51;
                else if (gage[id * 3] == 0 && gage[id * 3 + 1] != 0 && gage[id * 3 + 2] == 255)   gage[id * 3+1] -= 51;
                else if (gage[id * 3] != 255 && gage[id * 3 + 1] == 0 && gage[id * 3 + 2] == 255)   gage[id * 3 ] += 51;
                else if (gage[id * 3] == 255 && gage[id * 3 + 1] == 0 && gage[id * 3 + 2] != 0)   gage[id * 3+2] -= 51;
            }
        }
    }
    else {
        if (count == 3) {
            ggalive[id] = 1;
            gage[id * 3] = 255;
            gage[id * 3+1] = 255;
            gage[id * 3+2] = 0;


        }
    }

};




//Screen dimension constants
int SCREEN_WIDTH = 720;
int SCREEN_HEIGHT = 480;



bool init();

//Loads media
bool loadMedia();

//Frees media and shuts down SDL
void close();

//Loads individual image as texture
SDL_Texture* loadTexture(std::string path);

//The window we'll be rendering to
SDL_Window* gWindow = NULL;

//The window renderer
SDL_Renderer* gRenderer = NULL;

bool init()
{
    //Initialization flag
    bool success = true;

    //Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        printf("SDL could not initialize! SDL Error: %s\n", SDL_GetError());
        success = false;
    }
    else
    {
        //Set texture filtering to linear
        if (!SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1"))
        {
            printf("Warning: Linear texture filtering not enabled!");
        }

        //Create window
        gWindow = SDL_CreateWindow("SDL Tutorial", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
        if (gWindow == NULL)
        {
            printf("Window could not be created! SDL Error: %s\n", SDL_GetError());
            success = false;
        }
        else
        {
            //Create renderer for window
            gRenderer = SDL_CreateRenderer(gWindow, -1, SDL_RENDERER_ACCELERATED);
            if (gRenderer == NULL)
            {
                printf("Renderer could not be created! SDL Error: %s\n", SDL_GetError());
                success = false;
            }
            else
            {
                //Initialize renderer color
                SDL_SetRenderDrawColor(gRenderer, 0xFF, 0xFF, 0xFF, 0xFF);

                //Initialize PNG loading
                int imgFlags = IMG_INIT_PNG;
                if (!(IMG_Init(imgFlags) & imgFlags))
                {
                    printf("SDL_image could not initialize! SDL_image Error: %s\n", IMG_GetError());
                    success = false;
                }
            }
        }
    }

    return success;
}

bool loadMedia()
{
    //Loading success flag
    bool success = true;

    //Nothing to load
    return success;
}

void close()
{
    //Destroy window	
    SDL_DestroyRenderer(gRenderer);
    SDL_DestroyWindow(gWindow);
    gWindow = NULL;
    gRenderer = NULL;

    //Quit SDL subsystems
    IMG_Quit();
    SDL_Quit();
}

SDL_Texture* loadTexture(std::string path)
{
    //The final texture
    SDL_Texture* newTexture = NULL;

    //Load image at specified path
    SDL_Surface* loadedSurface = IMG_Load(path.c_str());
    if (loadedSurface == NULL)
    {
        printf("Unable to load image %s! SDL_image Error: %s\n", path.c_str(), IMG_GetError());
    }
    else
    {
        //Create texture from surface pixels
        newTexture = SDL_CreateTextureFromSurface(gRenderer, loadedSurface);
        if (newTexture == NULL)
        {
            printf("Unable to create texture from %s! SDL Error: %s\n", path.c_str(), SDL_GetError());
        }

        //Get rid of old loaded surface
        SDL_FreeSurface(loadedSurface);
    }

    return newTexture;
}


int main() {
    int cell_size = 10,temp;
    int alive[720/10][480/10];
    int age[720 / 10][480 / 10][3];
    FILE* fp;
    fp = fopen("somefile.txt", "r");

    for (int i = 0; i < SCREEN_WIDTH / cell_size; i++) {
        for (int j = 0; j < SCREEN_HEIGHT / cell_size; j++) {
            temp = rand();
            char str[1];
            if(temp%2==0)   alive[i][j] = 0;
            else   alive[i][j] = 1;
            //fscanf(fp, "%s", str);
            //alive[i][j]=stoi(str);
           
            age[i][j][0] = 255;
            age[i][j][1] = 255;
            age[i][j][2] = 0;
        }
    }
    fclose(fp);
    int* galive, * gage, *ggalive;
    cudaMalloc(&galive, (SCREEN_WIDTH / cell_size) * (SCREEN_HEIGHT / cell_size) * sizeof(int));
    cudaMalloc(&ggalive, (SCREEN_WIDTH / cell_size) * (SCREEN_HEIGHT / cell_size) * sizeof(int));
    cudaMalloc(&gage, (SCREEN_WIDTH / cell_size) * (SCREEN_HEIGHT / cell_size)*3 * sizeof(int));

    //Start up SDL and create window
	if( !init() )
	{
		printf( "Failed to initialize!\n" );
	}
	else
	{
		//Load media
		if( !loadMedia() )
		{
			printf( "Failed to load media!\n" );
		}
		else
		{	
			//Main loop flag
			bool quit = false;

			//Event handler
			SDL_Event e;

			//While application is running
			while( !quit )
			{
                /*for (int i = 0; i < SCREEN_WIDTH / cell_size; i++) {
                    printf("\n");
                    for (int j = 0; j < SCREEN_HEIGHT / cell_size; j++) {
                        printf("%d ", alive[i][j]);
                    }
                }printf("\n");*/
				//Handle events on queue
				while( SDL_PollEvent( &e ) != 0 )
				{
					//User requests quit
					if( e.type == SDL_QUIT )
					{
						quit = true;
					}
				}

				//Clear screen
				SDL_SetRenderDrawColor( gRenderer, 0xFF, 0xFF, 0xFF, 0xFF );
				SDL_RenderClear( gRenderer );

				//Render red filled quad
				//SDL_Rect fillRect = { SCREEN_WIDTH / 4, SCREEN_HEIGHT / 4, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2 };
				//SDL_SetRenderDrawColor( gRenderer, 0xFF, 0x00, 0x00, 0xFF );		
				//SDL_RenderFillRect( gRenderer, &fillRect );
                for (int i = 0; i < SCREEN_WIDTH/cell_size; i++) {
                    for (int j = 0; j < SCREEN_HEIGHT/cell_size; j++) {
                        if (alive[i][j] % 2 == 0) {
                            continue;
                        }
                        SDL_Rect fillRect = { i* cell_size, j * cell_size,cell_size, cell_size };
                        SDL_SetRenderDrawColor(gRenderer, age[i][j][0], age[i][j][1], age[i][j][2], 0xFF);
                        SDL_RenderFillRect(gRenderer, &fillRect); 
                    }
                }

				//Render green outlined quad
				/*SDL_Rect outlineRect = { SCREEN_WIDTH / 6, SCREEN_HEIGHT / 6, SCREEN_WIDTH * 2 / 3, SCREEN_HEIGHT * 2 / 3 };
				SDL_SetRenderDrawColor( gRenderer, 0x00, 0xFF, 0x00, 0xFF );		
				SDL_RenderDrawRect( gRenderer, &outlineRect );*/
				
				//Draw blue horizontal line
				SDL_SetRenderDrawColor( gRenderer, 0x00, 0, 255, 0xFF );		
				//SDL_RenderDrawLine( gRenderer, 0, SCREEN_HEIGHT / 2, SCREEN_WIDTH, SCREEN_HEIGHT / 2 );
                for (int i = 0; i < SCREEN_WIDTH/cell_size; i++) {
                    SDL_RenderDrawLine(gRenderer, i*cell_size, 0 , i*cell_size, SCREEN_HEIGHT );
                }
                for (int i = 0; i < SCREEN_HEIGHT/cell_size; i++) {
                    SDL_RenderDrawLine(gRenderer, 0, i*cell_size,SCREEN_WIDTH, i * cell_size);
                }
				//Draw vertical line of yellow dots
				SDL_SetRenderDrawColor( gRenderer, 0xFF, 0xFF, 0x00, 0xFF );
				/*for( int i = 0; i < SCREEN_HEIGHT; i += 4 )
				{
					SDL_RenderDrawPoint( gRenderer, SCREEN_WIDTH / 2, i );
				}*/

				//Update screen
				SDL_RenderPresent( gRenderer );
                cudaMemcpy(galive, alive, (SCREEN_WIDTH / cell_size) * (SCREEN_HEIGHT / cell_size) * sizeof(int), cudaMemcpyHostToDevice);
                cudaMemcpy(ggalive, alive, (SCREEN_WIDTH / cell_size) * (SCREEN_HEIGHT / cell_size) * sizeof(int), cudaMemcpyHostToDevice);
                cudaMemcpy(gage, age, (SCREEN_WIDTH / cell_size) * (SCREEN_HEIGHT / cell_size)*3 * sizeof(int), cudaMemcpyHostToDevice);
                next_species << <  SCREEN_WIDTH / cell_size, SCREEN_HEIGHT / cell_size  >> > (galive, ggalive, gage, (SCREEN_WIDTH / cell_size) * (SCREEN_HEIGHT / cell_size));
                cudaMemcpy(alive, ggalive, (SCREEN_WIDTH / cell_size) * (SCREEN_HEIGHT / cell_size) * sizeof(int), cudaMemcpyDeviceToHost);
                cudaMemcpy(age, gage, (SCREEN_WIDTH / cell_size) * (SCREEN_HEIGHT / cell_size)*3 * sizeof(int), cudaMemcpyDeviceToHost);
                SDL_Delay(50);
  
			}
		}
	}

	//Free resources and close SDL
	close();

    return 0;
}